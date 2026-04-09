output "resource_group_name" {
  description = "Nome do Resource Group principal."
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "ID da VNet hub."
  value       = module.networking.vnet_id
}

output "container_apps_environment_id" {
  description = "ID do Container Apps Environment."
  value       = module.container_apps_env.environment_id
}

output "grafana_url" {
  description = "URL pública do Grafana."
  value       = module.lgtm.grafana_url
}

output "alloy_otlp_endpoint" {
  description = "Endpoint OTLP do Alloy (gRPC)."
  value       = module.lgtm.alloy_otlp_endpoint
}

output "loki_endpoint" {
  description = "Endpoint interno do Loki."
  value       = module.lgtm.loki_endpoint
}

output "mimir_endpoint" {
  description = "Endpoint interno do Mimir."
  value       = module.lgtm.mimir_endpoint
}

output "tempo_endpoint" {
  description = "Endpoint interno do Tempo."
  value       = module.lgtm.tempo_endpoint
}

output "storage_account_name" {
  description = "Nome da Storage Account usada pelos backends."
  value       = module.storage.storage_account_name
}

output "postgres_fqdn" {
  description = "FQDN do PostgreSQL Flexible Server do Grafana."
  value       = azurerm_postgresql_flexible_server.grafana.fqdn
}

output "postgres_database_name" {
  description = "Nome do banco de dados do Grafana."
  value       = azurerm_postgresql_flexible_server_database.grafana.name
}
