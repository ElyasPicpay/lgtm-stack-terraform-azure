locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------
# Resource Group principal
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# Módulo: Networking
# ---------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  name_prefix                   = local.name_prefix
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  vnet_address_space            = var.vnet_address_space
  subnet_container_apps_cidr    = var.subnet_container_apps_cidr
  subnet_private_endpoints_cidr = var.subnet_private_endpoints_cidr
  tags                          = local.common_tags
}

# ---------------------------------------------------------------------------
# Módulo: Storage (backends S3-compatible para Loki, Mimir, Tempo)
# ---------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  name_prefix                           = local.name_prefix
  resource_group_name                   = azurerm_resource_group.main.name
  location                              = var.location
  storage_tier                          = var.storage_tier
  storage_replication_type              = var.storage_replication_type
  storage_public_network_access_enabled = var.storage_public_network_access_enabled
  subnet_private_endpoints_id           = module.networking.subnet_private_endpoints_id
  vnet_id                               = module.networking.vnet_id
  tags                                  = local.common_tags

  depends_on = [module.networking]
}

# ---------------------------------------------------------------------------
# Módulo: Container Apps Environment
# ---------------------------------------------------------------------------
module "container_apps_env" {
  source = "./modules/container_apps_env"

  name_prefix                  = local.name_prefix
  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  subnet_id                    = module.networking.subnet_container_apps_id
  log_analytics_sku            = var.log_analytics_sku
  log_analytics_retention_days = var.log_analytics_retention_days
  tags                         = local.common_tags

  depends_on = [module.networking]
}

# ---------------------------------------------------------------------------
# Módulo: Stack LGTM (Alloy + Loki + Mimir + Tempo + Grafana)
# ---------------------------------------------------------------------------
module "lgtm" {
  source = "./modules/lgtm"

  name_prefix            = local.name_prefix
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  container_apps_env_id  = module.container_apps_env.environment_id
  storage_account_name   = module.storage.storage_account_name
  storage_account_key    = module.storage.storage_account_key
  loki_container_name    = module.storage.loki_container_name
  mimir_container_name   = module.storage.mimir_container_name
  tempo_container_name   = module.storage.tempo_container_name
  grafana_admin_password = var.grafana_admin_password
  grafana_image          = var.grafana_image
  loki_image             = var.loki_image
  mimir_image            = var.mimir_image
  tempo_image            = var.tempo_image
  alloy_image            = var.alloy_image
  grafana_cpu            = var.grafana_cpu
  grafana_memory         = var.grafana_memory
  loki_cpu               = var.loki_cpu
  loki_memory            = var.loki_memory
  mimir_cpu              = var.mimir_cpu
  mimir_memory           = var.mimir_memory
  tempo_cpu              = var.tempo_cpu
  tempo_memory           = var.tempo_memory
  alloy_cpu              = var.alloy_cpu
  alloy_memory           = var.alloy_memory
  min_replicas           = var.min_replicas
  max_replicas           = var.max_replicas
  tags                   = local.common_tags

  depends_on = [module.container_apps_env, module.storage]
}
