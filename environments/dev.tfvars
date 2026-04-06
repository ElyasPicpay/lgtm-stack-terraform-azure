# ---------------------------------------------------------------------------
# dev.tfvars — ambiente de desenvolvimento
# ---------------------------------------------------------------------------

environment = "dev"
location    = "eastus2"
project     = "lgtm"

# Rede
vnet_address_space            = ["10.0.0.0/16"]
subnet_container_apps_cidr    = "10.0.0.0/23"
subnet_private_endpoints_cidr = "10.0.4.0/24"

# Storage
storage_tier             = "Standard"
storage_replication_type = "LRS"

# Log Analytics
log_analytics_sku            = "PerGB2018"
log_analytics_retention_days = 30

# Imagens (use tags fixas em produção — evite :latest)
grafana_image = "docker.io/grafana/grafana:11.1.0"
loki_image    = "docker.io/grafana/loki:3.1.0"
mimir_image   = "docker.io/grafana/mimir:2.13.0"
tempo_image   = "docker.io/grafana/tempo:2.5.0"
alloy_image   = "docker.io/grafana/alloy:v1.3.1"

# Recursos — tamanhos reduzidos para dev
grafana_cpu    = 0.5
grafana_memory = "1Gi"
loki_cpu       = 0.5
loki_memory    = "1Gi"
mimir_cpu      = 0.5
mimir_memory   = "1Gi"
tempo_cpu      = 0.5
tempo_memory   = "1Gi"
alloy_cpu      = 0.25
alloy_memory   = "512Mi"

# Réplicas
min_replicas = 1
max_replicas = 2

# Tags extras
tags = {
  owner    = "platform-team"
  costcenter = "eng-platform"
}

# Senha do Grafana — use variável de ambiente ou secret manager em CI/CD:
# export TF_VAR_grafana_admin_password="<senha>"
# grafana_admin_password = "DEFINA_VIA_TF_VAR"
