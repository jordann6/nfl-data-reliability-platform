variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "nfl-data-reliability-platform"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default = {
    project = "nfl-data-reliability-platform"
    env     = "dev"
    owner   = "jordann6"
  }
}

variable "project_short" {
  type        = string
  description = "Short project token for globally constrained names"
  default     = "nfldrp"
}

variable "kv_suffix" {
  type        = string
  description = "Short suffix for uniqueness within name limits"
  default     = "dev01"
}

variable "ingestor_fqdn" {
  type        = string
  description = "Ingestor container app FQDN, without scheme"
  default     = "ca-nfldrp-dev-ingestor.gentlemeadow-0da75c2e.eastus.azurecontainerapps.io"
}