variable "project_id" {
  type        = string
  description = "GCP 프로젝트 ID"
}

variable "gke_service_account_name" {
  description = "GKE 노드 서비스 계정 이름"
  type        = string
  default     = "gke-node-sa"
}

variable "gke_node_sa_email" {
  description = "Email of the shared GKE Node service account."
  type        = string
}
variable "gcr_sa_email" {
  description = "Email of the shared GCR Pull service account."
  type        = string
}
variable "cloud_sql_proxy_sa_email" {
  description = "Email of the shared Cloud SQL Proxy service account."
  type        = string
}
variable "external_secret_sa_email" {
  description = "Email of the shared External Secret service account."
  type        = string
}