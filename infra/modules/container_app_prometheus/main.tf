variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "container_app_env_id" {
  type = string
}

variable "scrape_target_fqdn" {
  type = string
}

variable "tags" {
  type = map(string)
}

resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_env_id
  revision_mode                = "Single"
  tags                         = var.tags

  ingress {
    external_enabled = true
    target_port      = 9090
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "prometheus"
      image  = "prom/prometheus:v2.54.1"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "SCRAPE_TARGET_FQDN"
        value = var.scrape_target_fqdn
      }

      command = [
        "/bin/sh",
        "-lc",
        <<EOT
cat > /etc/prometheus/prometheus.yml <<YAML
global:
  scrape_interval: 30s
scrape_configs:
  - job_name: "nfl_ingestor"
    metrics_path: /metrics
    scheme: https
    static_configs:
      - targets: ["$SCRAPE_TARGET_FQDN"]
YAML
exec /bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.retention.time=6h
EOT
      ]
    }
  }
}

output "fqdn" {
  value = azurerm_container_app.this.ingress[0].fqdn
}

output "url" {
  value = "https://${azurerm_container_app.this.ingress[0].fqdn}"
}
