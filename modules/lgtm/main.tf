# ---------------------------------------------------------------------------
# Loki config — modo monolítico com backend Azure Blob Storage
# ---------------------------------------------------------------------------
locals {
  loki_config = <<-YAML
    auth_enabled: false

    server:
      http_listen_port: 3100
      grpc_listen_port: 9095

    common:
      path_prefix: /loki
      replication_factor: 1
      storage:
        azure:
          account_name: ${var.storage_account_name}
          account_key: ${var.storage_account_key}
          container_name: ${var.loki_container_name}

    schema_config:
      configs:
        - from: 2024-01-01
          store: tsdb
          object_store: azure
          schema: v13
          index:
            prefix: loki_index_
            period: 24h

    storage_config:
      tsdb_shipper:
        active_index_directory: /loki/index
        cache_location: /loki/index_cache
      azure:
        account_name: ${var.storage_account_name}
        account_key: ${var.storage_account_key}
        container_name: ${var.loki_container_name}

    compactor:
      working_directory: /loki/compactor
      compaction_interval: 10m

    limits_config:
      reject_old_samples: true
      reject_old_samples_max_age: 168h
      ingestion_rate_mb: 64
      ingestion_burst_size_mb: 128

    analytics:
      reporting_enabled: false
  YAML

  # ---------------------------------------------------------------------------
  # Mimir config — modo monolítico com backend Azure Blob Storage
  # ---------------------------------------------------------------------------
  mimir_config = <<-YAML
    multitenancy_enabled: false

    common:
      storage:
        backend: azure
        azure:
          account_name: ${var.storage_account_name}
          account_key: ${var.storage_account_key}
          container_name: ${var.mimir_container_name}

    blocks_storage:
      azure:
        account_name: ${var.storage_account_name}
        account_key: ${var.storage_account_key}
        container_name: ${var.mimir_container_name}
      tsdb:
        dir: /data/ingester
      bucket_store:
        sync_dir: /data/tsdb-sync

    compactor:
      data_dir: /data/compactor

    ruler_storage:
      backend: azure
      azure:
        account_name: ${var.storage_account_name}
        account_key: ${var.storage_account_key}
        container_name: mimir-ruler

    alertmanager_storage:
      backend: azure
      azure:
        account_name: ${var.storage_account_name}
        account_key: ${var.storage_account_key}
        container_name: mimir-alertmanager

    ingester:
      ring:
        replication_factor: 1

    store_gateway:
      sharding_ring:
        replication_factor: 1

    analytics:
      reporting_enabled: false
  YAML

  # ---------------------------------------------------------------------------
  # Tempo config — modo monolítico com backend Azure Blob Storage
  # ---------------------------------------------------------------------------
  tempo_config = <<-YAML
    server:
      http_listen_port: 3200
      grpc_listen_port: 9095

    distributor:
      receivers:
        otlp:
          protocols:
            http: {}
            grpc: {}
        jaeger:
          protocols:
            thrift_http: {}
            grpc: {}
        zipkin: {}

    ingester:
      max_block_duration: 5m

    compactor:
      compaction:
        block_retention: 48h

    storage:
      trace:
        backend: azure
        azure:
          account_name: ${var.storage_account_name}
          account_key: ${var.storage_account_key}
          container_name: ${var.tempo_container_name}
        wal:
          path: /var/tempo/wal
        local:
          path: /var/tempo/blocks

    metrics_generator:
      registry:
        external_labels:
          source: tempo
      storage:
        path: /var/tempo/generator/wal

    overrides:
      defaults:
        metrics_generator:
          processors:
            - service-graphs
            - span-metrics
  YAML

  # ---------------------------------------------------------------------------
  # Alloy config — recebe OTLP, roteia para Loki/Mimir/Tempo
  # ---------------------------------------------------------------------------
  alloy_config = <<-ALLOY
    // ── OTLP receiver ──────────────────────────────────────────────────────
    otelcol.receiver.otlp "default" {
      grpc { endpoint = "0.0.0.0:4317" }
      http { endpoint = "0.0.0.0:4318" }

      output {
        metrics = [otelcol.processor.batch.default.input]
        logs    = [otelcol.processor.batch.default.input]
        traces  = [otelcol.processor.batch.default.input]
      }
    }

    // ── Batch processor ────────────────────────────────────────────────────
    otelcol.processor.batch "default" {
      output {
        metrics = [otelcol.exporter.prometheus.mimir.input]
        logs    = [otelcol.exporter.loki.loki.input]
        traces  = [otelcol.exporter.otlp.tempo.input]
      }
    }

    // ── Exporters ──────────────────────────────────────────────────────────
    otelcol.exporter.loki "loki" {
      forward_to = [loki.write.default.receiver]
    }

    loki.write "default" {
      endpoint {
        url = "http://ca-${var.name_prefix}-loki:3100/loki/api/v1/push"
      }
    }

    otelcol.exporter.prometheus "mimir" {
      forward_to = [prometheus.remote_write.mimir.receiver]
    }

    prometheus.remote_write "mimir" {
      endpoint {
        url = "http://ca-${var.name_prefix}-mimir:8080/api/v1/push"
      }
    }

    otelcol.exporter.otlp "tempo" {
      client {
        endpoint = "ca-${var.name_prefix}-tempo:4317"
        tls { insecure = true }
      }
    }
  ALLOY
}

# ---------------------------------------------------------------------------
# Loki
# ---------------------------------------------------------------------------
resource "azurerm_container_app" "loki" {
  name                         = "ca-${var.name_prefix}-loki"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_apps_env_id
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "loki"
      image  = var.loki_image
      cpu    = var.loki_cpu
      memory = var.loki_memory
      args   = ["-config.file=/etc/loki/loki.yaml"]

      env {
        name  = "LOKI_CONFIG_CONTENT"
        value = base64encode(local.loki_config)
      }

      # Loki aceita config via stdin / arquivo; injetamos via env + command
      command = [
        "/bin/sh", "-c",
        "echo $LOKI_CONFIG_CONTENT | base64 -d > /etc/loki/loki.yaml && /usr/bin/loki -config.file=/etc/loki/loki.yaml"
      ]
    }
  }

  ingress {
    external_enabled = false
    target_port      = 3100
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# ---------------------------------------------------------------------------
# Mimir
# ---------------------------------------------------------------------------
resource "azurerm_container_app" "mimir" {
  name                         = "ca-${var.name_prefix}-mimir"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_apps_env_id
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "mimir"
      image  = var.mimir_image
      cpu    = var.mimir_cpu
      memory = var.mimir_memory

      env {
        name  = "MIMIR_CONFIG_CONTENT"
        value = base64encode(local.mimir_config)
      }

      command = [
        "/bin/sh", "-c",
        "echo $MIMIR_CONFIG_CONTENT | base64 -d > /etc/mimir/mimir.yaml && /bin/mimir -config.file=/etc/mimir/mimir.yaml"
      ]
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8080
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# ---------------------------------------------------------------------------
# Tempo
# ---------------------------------------------------------------------------
resource "azurerm_container_app" "tempo" {
  name                         = "ca-${var.name_prefix}-tempo"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_apps_env_id
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "tempo"
      image  = var.tempo_image
      cpu    = var.tempo_cpu
      memory = var.tempo_memory

      env {
        name  = "TEMPO_CONFIG_CONTENT"
        value = base64encode(local.tempo_config)
      }

      command = [
        "/bin/sh", "-c",
        "echo $TEMPO_CONFIG_CONTENT | base64 -d > /etc/tempo/tempo.yaml && /tempo -config.file=/etc/tempo/tempo.yaml"
      ]
    }
  }

  ingress {
    external_enabled = false
    target_port      = 3200
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# ---------------------------------------------------------------------------
# Alloy (Hub — coleta telemetria e roteia)
# ---------------------------------------------------------------------------
resource "azurerm_container_app" "alloy" {
  name                         = "ca-${var.name_prefix}-alloy"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_apps_env_id
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "alloy"
      image  = var.alloy_image
      cpu    = var.alloy_cpu
      memory = var.alloy_memory

      env {
        name  = "ALLOY_CONFIG_CONTENT"
        value = base64encode(local.alloy_config)
      }

      command = [
        "/bin/sh", "-c",
        "echo $ALLOY_CONFIG_CONTENT | base64 -d > /etc/alloy/config.alloy && /bin/alloy run /etc/alloy/config.alloy"
      ]
    }
  }

  # OTLP gRPC (4317) e HTTP (4318) — acessível externamente para os apps
  ingress {
    external_enabled = true
    target_port      = 4318
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  depends_on = [
    azurerm_container_app.loki,
    azurerm_container_app.mimir,
    azurerm_container_app.tempo,
  ]
}

# ---------------------------------------------------------------------------
# Grafana
# ---------------------------------------------------------------------------
resource "azurerm_container_app" "grafana" {
  name                         = "ca-${var.name_prefix}-grafana"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_apps_env_id
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "grafana"
      image  = var.grafana_image
      cpu    = var.grafana_cpu
      memory = var.grafana_memory

      env {
        name  = "GF_SECURITY_ADMIN_PASSWORD"
        value = var.grafana_admin_password
      }

      env {
        name  = "GF_DATABASE_TYPE"
        value = "postgres"
      }

      env {
        name  = "GF_DATABASE_HOST"
        value = "${var.grafana_database_host}:${var.grafana_database_port}"
      }

      env {
        name  = "GF_DATABASE_NAME"
        value = var.grafana_database_name
      }

      env {
        name  = "GF_DATABASE_USER"
        value = var.grafana_database_user
      }

      env {
        name  = "GF_DATABASE_PASSWORD"
        value = var.grafana_database_pass
      }

      env {
        name  = "GF_DATABASE_SSL_MODE"
        value = var.grafana_database_ssl_mode
      }

      # Provisiona datasources automaticamente via env
      env {
        name  = "GF_PATHS_PROVISIONING"
        value = "/etc/grafana/provisioning"
      }

      # Datasource Loki
      env {
        name  = "GF_DATASOURCES_LOKI_URL"
        value = "http://ca-${var.name_prefix}-loki:3100"
      }

      # Datasource Mimir (Prometheus-compatible)
      env {
        name  = "GF_DATASOURCES_MIMIR_URL"
        value = "http://ca-${var.name_prefix}-mimir:8080/prometheus"
      }

      # Datasource Tempo
      env {
        name  = "GF_DATASOURCES_TEMPO_URL"
        value = "http://ca-${var.name_prefix}-tempo:3200"
      }

      # Plugin correlação Loki<->Tempo
      env {
        name  = "GF_FEATURE_TOGGLES_ENABLE"
        value = "traceToMetrics,correlations"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  depends_on = [
    azurerm_container_app.loki,
    azurerm_container_app.mimir,
    azurerm_container_app.tempo,
  ]
}
