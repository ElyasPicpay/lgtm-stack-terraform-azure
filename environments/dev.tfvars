# ---------------------------------------------------------------------------
# dev.tfvars — ambiente de desenvolvimento
# ---------------------------------------------------------------------------

environment = "dev"
location    = "brazilsouth"
project     = "lgtm"

# Rede
vnet_address_space            = ["10.0.0.0/16"]
subnet_container_apps_cidr    = "10.0.0.0/23"
subnet_private_endpoints_cidr = "10.0.4.0/24"

# Storage
storage_tier                          = "Standard"
storage_replication_type              = "LRS"
storage_public_network_access_enabled = true

# Log Analytics
log_analytics_sku            = "PerGB2018"
log_analytics_retention_days = 30

# Imagens (use tags fixas em produção — evite :latest)
grafana_image = "docker.io/grafana/grafana:latest"
loki_image    = "docker.io/grafana/loki:latest"
mimir_image   = "docker.io/grafana/mimir:latest"
tempo_image   = "docker.io/grafana/tempo:latest"
alloy_image   = "docker.io/grafana/alloy:latest"

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
alloy_memory   = "0.5Gi"

# Réplicas
min_replicas = 1
max_replicas = 2

# Tags extras
tags = {
  owner       = "platform-team"
  costcenter  = "eng-platform"
}

# Senha do Grafana — use variável de ambiente ou secret manager em CI/CD:
# export TF_VAR_grafana_admin_password="<senha>"
# Senha do PostgreSQL do Grafana:
# export TF_VAR_postgres_admin_password="<senha>"
# grafana_admin_password = "DEFINA_VIA_TF_VAR"
