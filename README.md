# LGTM Stack — Azure Container Apps (Terraform)

Infraestrutura como código para stack de observabilidade LGTM no Azure, composta por:

| Serviço | Função |
|---------|--------|
| **Grafana Alloy** | Coleta, normaliza e roteia telemetria (logs, métricas, traces) |
| **Loki** | Armazenamento e consulta de logs |
| **Mimir** | Armazenamento e consulta de métricas (Prometheus-compatible) |
| **Tempo** | Armazenamento e consulta de traces distribuídos |
| **Grafana** | Visualização e correlação dos três sinais |

## Arquitetura

```
                     +----------------------+
                     |     Grafana UI       |
                     | (dashboards/alertas) |
                     +----------+-----------+
                                |
                  consulta logs | métricas | traces
                                |
    +-------------+   +---------v---------+   +-------------+
    |    Loki     |   |      Mimir        |   |    Tempo    |
    |   (logs)    |   |    (métricas)     |   |   (traces)  |
    +------+------+   +---------+---------+   +------+------+
           ^                    ^                    ^
           |                    |                    |
           +---------+----------+----------+---------+
                     |      Alloy Hub      |
                     | coleta/processa/envia|
                     +----------+----------+
                                ^
                   telemetria (OTLP gRPC/HTTP)
                                |
 +----------------+------------------+------------------+
 | Container App A| Container App B  | Container App N  |
 +----------------+------------------+------------------+

Rede:
- VNet hub com subnet dedicada ao Container Apps Environment
- Private Endpoint para Storage Account (blobs)
- DNS Privado para resolução interna do Storage
```

## Estrutura do projeto

```
terraform/
├── main.tf                         # Root: RG + chamada de módulos
├── variables.tf                    # Variáveis globais
├── outputs.tf                      # Outputs: URLs, IDs
├── versions.tf                     # Providers e versões
├── environments/
│   ├── dev.tfvars                  # Sizing reduzido, LRS
│   └── prod.tfvars                 # Sizing prod, ZRS, mais réplicas
└── modules/
    ├── networking/                 # VNet, subnets, NSG, Private DNS
    ├── storage/                    # Storage Account + containers blob
    ├── container_apps_env/         # Container Apps Environment + Log Analytics
    └── lgtm/                       # Alloy, Loki, Mimir, Tempo, Grafana
```

## Pré-requisitos

- Terraform >= 1.7.0
- Azure CLI autenticado (`az login`)
- Subscription com cotas suficientes para Container Apps e Storage
- Feature `Microsoft.App` registrada na subscription:
  ```bash
  az provider register --namespace Microsoft.App
  az provider register --namespace Microsoft.OperationalInsights
  ```

## Deploy

```bash
cd terraform

# 1. Inicializar providers e módulos
terraform init

# 2. Definir senha do Grafana (nunca no tfvars)
export TF_VAR_grafana_admin_password="sua-senha-segura"

# 3. Planejar
terraform plan -var-file=environments/dev.tfvars -out=tfplan

# 4. Aplicar
terraform apply tfplan
```

## Outputs esperados

Após o apply, os seguintes valores estarão disponíveis:

| Output | Descrição |
|--------|-----------|
| `grafana_url` | URL pública do Grafana |
| `alloy_otlp_endpoint` | Endpoint OTLP HTTP do Alloy para seus apps |
| `loki_endpoint` | Endpoint interno do Loki |
| `mimir_endpoint` | Endpoint interno do Mimir |
| `tempo_endpoint` | Endpoint interno do Tempo |
| `storage_account_name` | Nome da Storage Account dos backends |

## Integrar um app com o Alloy

Configure seu Container App para enviar telemetria OTLP para o Alloy:

```bash
# Obtendo o endpoint
ALLOY_URL=$(terraform output -raw alloy_otlp_endpoint)

# Variáveis de ambiente no seu app
OTEL_EXPORTER_OTLP_ENDPOINT=$ALLOY_URL
OTEL_SERVICE_NAME=meu-servico
OTEL_RESOURCE_ATTRIBUTES=environment=dev,team=platform
```

## Backends de storage

Cada serviço usa um container blob dedicado:

| Serviço | Container |
|---------|-----------|
| Loki (chunks) | `loki-chunks` |
| Loki (ruler) | `loki-ruler` |
| Mimir (blocks) | `mimir-blocks` |
| Mimir (ruler) | `mimir-ruler` |
| Mimir (alertmanager) | `mimir-alertmanager` |
| Tempo (traces) | `tempo-traces` |

## Segurança

- Storage Account sem acesso público — tráfego via Private Endpoint
- NSG restringe ingress: apenas HTTPS (443) e OTLP (4317/4318) externos
- `grafana_admin_password` marcada como `sensitive` no Terraform
- Nunca commitar senhas nos `.tfvars` — use `TF_VAR_*` ou Key Vault

## Remote State (recomendado para times)

Descomente e ajuste o bloco `backend "azurerm"` em `versions.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "stterraformstate"
  container_name       = "tfstate"
  key                  = "lgtm/terraform.tfstate"
}
```

Inicialize com:
```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate"
```
