variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-${var.name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  tags                       = var.tags
}

output "environment_id" { value = azurerm_container_app_environment.this.id }
output "environment_name" { value = azurerm_container_app_environment.this.name }
output "log_analytics_id" { value = azurerm_log_analytics_workspace.this.id }
output "log_analytics_name" { value = azurerm_log_analytics_workspace.this.name }