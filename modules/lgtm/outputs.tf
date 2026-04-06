output "grafana_url" {
  description = "URL pública do Grafana."
  value       = "https://${azurerm_container_app.grafana.ingress[0].fqdn}"
}

output "alloy_otlp_endpoint" {
  description = "Endpoint OTLP HTTP do Alloy (4318)."
  value       = "https://${azurerm_container_app.alloy.ingress[0].fqdn}"
}

output "loki_endpoint" {
  description = "Endpoint interno do Loki."
  value       = "http://ca-${var.name_prefix}-loki:3100"
}

output "mimir_endpoint" {
  description = "Endpoint interno do Mimir."
  value       = "http://ca-${var.name_prefix}-mimir:8080"
}

output "tempo_endpoint" {
  description = "Endpoint interno do Tempo."
  value       = "http://ca-${var.name_prefix}-tempo:3200"
}

output "loki_app_fqdn" {
  value = azurerm_container_app.loki.ingress[0].fqdn
}

output "mimir_app_fqdn" {
  value = azurerm_container_app.mimir.ingress[0].fqdn
}

output "tempo_app_fqdn" {
  value = azurerm_container_app.tempo.ingress[0].fqdn
}
