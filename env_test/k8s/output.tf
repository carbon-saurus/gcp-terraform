output "gcpsm_secret_names" {
  value = { for k, v in google_secret_manager_secret.project_gsm : k => k }
}

output "gcpsm_secret_gsm_paths" {
  value = { for k, v in google_secret_manager_secret.project_gsm : k => v.name }
}