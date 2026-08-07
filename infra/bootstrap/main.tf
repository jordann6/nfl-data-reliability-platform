resource "azurerm_resource_group" "tfstate" {
  name     = var.tfstate_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "random_string" "suffix" {
  length  = 10
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  storage_account_name = substr("${var.storage_account_prefix}${random_string.suffix.result}", 0, 24)
}

resource "azurerm_storage_account" "tfstate" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
  }

  tags = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.tfstate_container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}