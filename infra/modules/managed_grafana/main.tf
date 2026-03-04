variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "grafana_major_version" {
  type    = string
  default = "11"
}

variable "tags" {
  type = map(string)
}

resource "azurerm_dashboard_grafana" "this" {
  name                  = var.name
  resource_group_name   = var.resource_group_name
  location              = var.location
  grafana_major_version = var.grafana_major_version

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

output "name" {
  value = azurerm_dashboard_grafana.this.name
}

output "id" {
  value = azurerm_dashboard_grafana.this.id
}
