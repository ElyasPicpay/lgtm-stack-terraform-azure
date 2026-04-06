variable "name_prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "container_apps_env_id" { type = string }
variable "storage_account_name" { type = string }
variable "storage_account_key" {
  type      = string
  sensitive = true
}
variable "loki_container_name" { type = string }
variable "mimir_container_name" { type = string }
variable "tempo_container_name" { type = string }
variable "grafana_admin_password" {
  type      = string
  sensitive = true
}
variable "grafana_image" { type = string }
variable "loki_image" { type = string }
variable "mimir_image" { type = string }
variable "tempo_image" { type = string }
variable "alloy_image" { type = string }
variable "grafana_cpu" { type = number }
variable "grafana_memory" { type = string }
variable "loki_cpu" { type = number }
variable "loki_memory" { type = string }
variable "mimir_cpu" { type = number }
variable "mimir_memory" { type = string }
variable "tempo_cpu" { type = number }
variable "tempo_memory" { type = string }
variable "alloy_cpu" { type = number }
variable "alloy_memory" { type = string }
variable "min_replicas" { type = number }
variable "max_replicas" { type = number }
variable "tags" { type = map(string) }
