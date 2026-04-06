resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ---------------------------------------------------------------------------
# Storage Account
# Nome: máximo 24 chars, só minúsculas e números
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "lgtm" {
  name                     = "st${replace(var.name_prefix, "-", "")}${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_tier
  account_replication_type = var.storage_replication_type
  min_tls_version          = "TLS1_2"

  # Quando o Terraform roda fora da VNet privada, o data-plane de blobs
  # precisa de endpoint publico para gerenciar os containers.
  public_network_access_enabled   = var.storage_public_network_access_enabled
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Blob containers — um por backend
# ---------------------------------------------------------------------------
resource "azurerm_storage_container" "loki" {
  name                  = "loki-chunks"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "loki_ruler" {
  name                  = "loki-ruler"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "mimir_blocks" {
  name                  = "mimir-blocks"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "mimir_ruler" {
  name                  = "mimir-ruler"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "mimir_alertmanager" {
  name                  = "mimir-alertmanager"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "tempo" {
  name                  = "tempo-traces"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

# ---------------------------------------------------------------------------
# Private Endpoint — Storage Blob
# ---------------------------------------------------------------------------
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-${var.name_prefix}-stblob"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_private_endpoints_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name_prefix}-stblob"
    private_connection_resource_id = azurerm_storage_account.lgtm.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
