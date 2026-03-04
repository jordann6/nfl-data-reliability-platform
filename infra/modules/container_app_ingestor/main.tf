variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "container_app_env_id" { type = string }

variable "image" { type = string }
variable "registry_server" { type = string }
variable "registry_identity" { type = string }

variable "workload_identity_id" { type = string }

variable "storage_account_name" { type = string }
variable "sports_api_url" { type = string }

variable "ingest_interval_seconds" {
  type    = number
  default = 300
}

variable "tags" { type = map(string) }

resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_env_id
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.workload_identity_id, var.registry_identity]
  }

  registry {
    server   = var.registry_server
    identity = var.registry_identity
  }

  ingress {
    external_enabled = true
    target_port      = 8000
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
      name   = "ingestor"
      image  = var.image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AZURE_STORAGE_ACCOUNT_NAME"
        value = var.storage_account_name
      }

      env {
        name  = "SPORTS_API_URL"
        value = var.sports_api_url
      }

      env {
        name  = "INGEST_INTERVAL_SECONDS"
        value = tostring(var.ingest_interval_seconds)
      }

      env {
        name  = "BLOB_CONTAINER_RAW"
        value = "raw"
      }

      env {
        name  = "BLOB_CONTAINER_PROCESSED"
        value = "processed"
      }

      env {
        name  = "BLOB_CONTAINER_QUARANTINE"
        value = "quarantine"
      }
    }
  }
}

output "name" {
  value = azurerm_container_app.this.name
}

output "fqdn" {
  value = azurerm_container_app.this.ingress[0].fqdn
}

output "url" {
  value = "https://${azurerm_container_app.this.ingress[0].fqdn}"
}
