output "storage_account_name" {
  value = azurerm_storage_account.lgtm.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.lgtm.primary_access_key
  sensitive = true
}

output "storage_account_id" {
  value = azurerm_storage_account.lgtm.id
}

output "loki_container_name" {
  value = azurerm_storage_container.loki.name
}

output "loki_ruler_container_name" {
  value = azurerm_storage_container.loki_ruler.name
}

output "mimir_container_name" {
  value = azurerm_storage_container.mimir_blocks.name
}

output "mimir_ruler_container_name" {
  value = azurerm_storage_container.mimir_ruler.name
}

output "mimir_alertmanager_container_name" {
  value = azurerm_storage_container.mimir_alertmanager.name
}

output "tempo_container_name" {
  value = azurerm_storage_container.tempo.name
}

output "private_endpoint_ip" {
  value = azurerm_private_endpoint.storage_blob.private_service_connection[0].private_ip_address
}
