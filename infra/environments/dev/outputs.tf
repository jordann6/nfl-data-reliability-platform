output "resource_group_name" {
  value = module.workload_rg.name
}

output "ingestor_uami_id" {
  value     = module.ingestor_uami.id
  sensitive = true
}

output "ingestor_uami_client_id" {
  value     = module.ingestor_uami.client_id
  sensitive = true
}

output "ingestor_uami_principal_id" {
  value     = module.ingestor_uami.principal_id
  sensitive = true
}

output "key_vault_name" {
  value = module.key_vault.name
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "data_storage_account_name" {
  value = module.data_storage.storage_account_name
}

output "data_storage_container_names" {
  value = module.data_storage.container_names
}

output "acr_name" {
  value = module.acr.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "container_apps_env_name" {
  value = module.container_apps_env.environment_name
}

output "log_analytics_name" {
  value = module.container_apps_env.log_analytics_name
}
output "ingestor_app_url" {
  value = module.ingestor_app.url
}
output "grafana_name" {
  value = module.grafana.name
}

output "prometheus_url" {
  value = module.prometheus_app.url
}