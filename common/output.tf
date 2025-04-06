output "gke_service_account" {
  value = google_service_account.gke_service_account.email
}

output "gcr_service_account" {
  description = "The email address of the GCR pull service account"
  value       = google_service_account.gcr_pull.email
}

output "cloud_sql_proxy_service_account" {
  description = "The email address of the Cloud SQL Proxy service account"
  value       = google_service_account.cloud_sql_proxy.email
}


output "external_secret_service_account" {
  description = "The email address of the Cloud SQL Proxy service account"
  value       = google_service_account.external_es.email
}

output "cloud_sql_proxy_sa_key_private_key_data" {
  description = "Base64 encoded private key data for the Cloud SQL Proxy service account key"
  value       = google_service_account_key.cloud_sql_proxy.private_key
  sensitive   = true
}

output "external_es_key_private_key_data" {
  description = "External Secret service account key"
  value = google_service_account_key.external_es_key.private_key
  sensitive   = true
}

output "gcr_sa_key_private_key_data" {
  description = "Artifact Registry service account key"
  value = google_service_account_key.gcr_pull_key.private_key
  sensitive   = true
}