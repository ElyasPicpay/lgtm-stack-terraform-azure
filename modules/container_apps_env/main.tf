# ---------------------------------------------------------------------------
# Log Analytics Workspace
# Obrigatório para o Container Apps Environment
# ---------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Container Apps Environment (workload profiles = Consumption)
# Modo VNet-integrated para tráfego privado entre os serviços LGTM
# ---------------------------------------------------------------------------
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.name_prefix}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Integração VNet — subnet com delegação Microsoft.App/environments
  infrastructure_subnet_id       = var.subnet_id
  internal_load_balancer_enabled = false # true = só acesso interno (sem IP público)

  tags = var.tags
}
