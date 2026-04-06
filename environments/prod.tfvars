# ---------------------------------------------------------------------------
# prod.tfvars — ambiente de produção
# ---------------------------------------------------------------------------

environment = "prod"
location    = "eastus2"
project     = "lgtm"

# Rede
vnet_address_space            = ["10.1.0.0/16"]
subnet_container_apps_cidr    = "10.1.0.0/23"
subnet_private_endpoints_cidr = "10.1.4.0/24"

# Storage — ZRS em prod para maior durabilidade
storage_tier             = "Standard"
storage_replication_type = "ZRS"

# Log Analytics
log_analytics_sku            = "PerGB2018"
log_analytics_retention_days = 90

# Imagens — fixas, sem floating tags
grafana_image = "docker.io/grafana/grafana:11.1.0"
loki_image    = "docker.io/grafana/loki:3.1.0"
mimir_image   = "docker.io/grafana/mimir:2.13.0"
tempo_image   = "docker.io/grafana/tempo:2.5.0"
alloy_image   = "docker.io/grafana/alloy:v1.3.1"

# Recursos — sizing adequado para prod
grafana_cpu    = 1.0
grafana_memory = "2Gi"
loki_cpu       = 1.0
loki_memory    = "2Gi"
mimir_cpu      = 1.0
mimir_memory   = "2Gi"
tempo_cpu      = 1.0
tempo_memory   = "2Gi"
alloy_cpu      = 0.5
alloy_memory   = "1Gi"

# Réplicas
min_replicas = 2
max_replicas = 5

# Tags extras
tags = {
  owner       = "platform-team"
  costcenter  = "eng-platform"
  criticality = "high"
}

# grafana_admin_password — NUNCA commitar. Injetar via:
# export TF_VAR_grafana_admin_password="$(az keyvault secret show ...)"
