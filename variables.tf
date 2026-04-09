# ---------------------------------------------------------------------------
# Contexto geral
# ---------------------------------------------------------------------------
variable "project" {
  description = "Nome curto do projeto, usado como prefixo nos recursos."
  type        = string
  default     = "lgtm"
}

variable "environment" {
  description = "Ambiente de deploy (dev | staging | prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Valores aceitos: dev, staging, prod."
  }
}

variable "location" {
  description = "Região Azure onde os recursos serão criados."
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags adicionais aplicadas a todos os recursos."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Rede
# ---------------------------------------------------------------------------
variable "vnet_address_space" {
  description = "Espaço de endereçamento da VNet hub."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_container_apps_cidr" {
  description = "CIDR da subnet dedicada ao Container Apps Environment (mínimo /23)."
  type        = string
  default     = "10.0.0.0/23"
}

variable "subnet_private_endpoints_cidr" {
  description = "CIDR da subnet para Private Endpoints de Storage etc."
  type        = string
  default     = "10.0.4.0/24"
}

# ---------------------------------------------------------------------------
# Storage (backends Loki / Mimir / Tempo)
# ---------------------------------------------------------------------------
variable "storage_replication_type" {
  description = "Tipo de replicação da Storage Account (LRS | ZRS | GRS)."
  type        = string
  default     = "LRS"
}

variable "storage_tier" {
  description = "Tier da Storage Account (Standard | Premium)."
  type        = string
  default     = "Standard"
}

variable "storage_public_network_access_enabled" {
  description = "Habilita acesso publico na Storage Account para permitir operacoes de data-plane via Terraform fora da VNet privada."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Container Apps Environment
# ---------------------------------------------------------------------------
variable "log_analytics_sku" {
  description = "SKU do Log Analytics Workspace atrelado ao ambiente."
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Retenção de logs no Log Analytics (dias)."
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# LGTM — configurações dos serviços
# ---------------------------------------------------------------------------
variable "grafana_admin_password" {
  description = "Senha do admin inicial do Grafana."
  type        = string
  sensitive   = true
}

variable "postgres_admin_username" {
  description = "Usuario administrador do PostgreSQL Flexible Server."
  type        = string
  default     = "pgadmin"
}

variable "postgres_admin_password" {
  description = "Senha do usuario administrador do PostgreSQL Flexible Server."
  type        = string
  sensitive   = true
}

variable "postgres_database_name" {
  description = "Nome do banco de dados usado pelo Grafana."
  type        = string
  default     = "grafana"
}

variable "postgres_sku_name" {
  description = "SKU do PostgreSQL Flexible Server (ex: B_Standard_B1ms, B_Standard_B2s, GP_Standard_D2s_v3)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "Armazenamento em MB do PostgreSQL Flexible Server."
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "Versao principal do PostgreSQL."
  type        = string
  default     = "16"
}

variable "postgres_public_network_access_enabled" {
  description = "Habilita acesso publico ao PostgreSQL Flexible Server."
  type        = bool
  default     = true
}

variable "grafana_image" {
  description = "Imagem Docker do Grafana."
  type        = string
  default     = "docker.io/grafana/grafana:11.1.0"
}

variable "loki_image" {
  description = "Imagem Docker do Loki."
  type        = string
  default     = "docker.io/grafana/loki:3.1.0"
}

variable "mimir_image" {
  description = "Imagem Docker do Mimir."
  type        = string
  default     = "docker.io/grafana/mimir:2.13.0"
}

variable "tempo_image" {
  description = "Imagem Docker do Tempo."
  type        = string
  default     = "docker.io/grafana/tempo:2.5.0"
}

variable "alloy_image" {
  description = "Imagem Docker do Grafana Alloy."
  type        = string
  default     = "docker.io/grafana/alloy:v1.3.1"
}

# Recursos de CPU/memória por serviço ----------------------------------------
variable "grafana_cpu" {
  type    = number
  default = 0.5
}
variable "grafana_memory" {
  type    = string
  default = "1Gi"
}

variable "loki_cpu" {
  type    = number
  default = 0.5
}
variable "loki_memory" {
  type    = string
  default = "1Gi"
}

variable "mimir_cpu" {
  type    = number
  default = 0.5
}
variable "mimir_memory" {
  type    = string
  default = "1Gi"
}

variable "tempo_cpu" {
  type    = number
  default = 0.5
}
variable "tempo_memory" {
  type    = string
  default = "1Gi"
}

variable "alloy_cpu" {
  type    = number
  default = 0.25
}
variable "alloy_memory" {
  type    = string
  default = "512Mi"
}

# Replicas mínimas / máximas ---------------------------------------------------
variable "min_replicas" {
  description = "Réplicas mínimas para todos os serviços LGTM."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Réplicas máximas para todos os serviços LGTM."
  type        = number
  default     = 3
}
