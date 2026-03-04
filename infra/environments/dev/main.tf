data "azurerm_client_config" "current" {}

module "workload_rg" {
  source   = "../../modules/workload_rg"
  name     = "rg-${var.project}-${var.env}"
  location = var.location
  tags     = var.tags
}

module "ingestor_uami" {
  source              = "../../modules/identity_uami"
  name                = "uami-${var.project}-${var.env}-ingestor"
  location            = var.location
  resource_group_name = module.workload_rg.name
  tags                = var.tags
}

module "key_vault" {
  source              = "../../modules/key_vault"
  name                = "kvnfldrpdev01"
  location            = var.location
  resource_group_name = module.workload_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags
}

module "data_storage" {
  source                = "../../modules/blob_storage"
  name_prefix           = "stnfldrp"
  location              = var.location
  resource_group_name   = module.workload_rg.name
  containers            = ["raw", "processed", "quarantine"]
  ingestor_principal_id = module.ingestor_uami.principal_id
  tags                  = var.tags
}
module "acr" {
  source              = "../../modules/acr"
  name_prefix         = "acrnfldrp"
  location            = var.location
  resource_group_name = module.workload_rg.name
  sku                 = "Basic"
  tags                = var.tags
}

module "container_apps_env" {
  source              = "../../modules/container_apps_env"
  name                = "nfldrp-${var.env}"
  location            = var.location
  resource_group_name = module.workload_rg.name
  tags                = var.tags
}

module "acr_pull_uami" {
  source              = "../../modules/acr_pull_identity"
  name                = "uami-nfldrp-${var.env}-acrpull"
  location            = var.location
  resource_group_name = module.workload_rg.name
  acr_id              = module.acr.id
  tags                = var.tags
}
module "ingestor_app" {
  source               = "../../modules/container_app_ingestor"
  name                 = "ca-nfldrp-${var.env}-ingestor"
  resource_group_name  = module.workload_rg.name
  location             = var.location
  container_app_env_id = module.container_apps_env.environment_id

  image             = "${module.acr.login_server}/nfl-ingestor:dev"
  registry_server   = module.acr.login_server
  registry_identity = module.acr_pull_uami.id

  workload_identity_id = module.ingestor_uami.id

  storage_account_name    = module.data_storage.storage_account_name
  sports_api_url          = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard"
  ingest_interval_seconds = 300

  tags = var.tags
}

module "grafana" {
  source              = "../../modules/managed_grafana"
  name                = "gfnfldrp${var.env}"
  location            = var.location
  resource_group_name = module.workload_rg.name
  tags                = var.tags
}

module "prometheus_app" {
  source               = "../../modules/container_app_prometheus"
  name                 = "ca-nfldrp-${var.env}-prom"
  resource_group_name  = module.workload_rg.name
  location             = var.location
  container_app_env_id = module.container_apps_env.environment_id

  scrape_target_fqdn = var.ingestor_fqdn
  tags               = var.tags
}