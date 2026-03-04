variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "acr_id" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

output "id" { value = azurerm_user_assigned_identity.this.id }
output "client_id" { value = azurerm_user_assigned_identity.this.client_id }
output "principal_id" { value = azurerm_user_assigned_identity.this.principal_id }
output "name" { value = azurerm_user_assigned_identity.this.name }
