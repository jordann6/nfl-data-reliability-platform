variable "location" {
  type        = string
  description = "Azure region for the bootstrap backend resources"
  default     = "eastus"
}

variable "tfstate_resource_group_name" {
  type        = string
  description = "Resource group name that will hold the Terraform state backend"
  default     = "rg-tfstate-nfl-drp-dev"
}

variable "tfstate_container_name" {
  type        = string
  description = "Blob container name for Terraform state"
  default     = "tfstate"
}

variable "storage_account_prefix" {
  type        = string
  description = "Prefix for the storage account name, must be lowercase letters and numbers only"
  default     = "tfsnfl"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to bootstrap resources"
  default = {
    project = "nfl-data-reliability-platform"
    env     = "dev"
    owner   = "jordann6"
  }
}