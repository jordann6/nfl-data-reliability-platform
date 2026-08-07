variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "containers" { type = list(string) }
variable "ingestor_principal_id" { type = string }
variable "tags" { type = map(string) }

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  storage_account_name = substr("${var.name_prefix}${random_string.suffix.result}", 0, 24)
}

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each              = toset(var.containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "ingestor_blob_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.ingestor_principal_id
}

output "storage_account_name" { value = azurerm_storage_account.this.name }
output "storage_account_id" { value = azurerm_storage_account.this.id }
output "container_names" { value = [for c in azurerm_storage_container.this : c.name] }