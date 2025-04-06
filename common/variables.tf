variable "project" {
  type        = string
  description = "GCP 프로젝트 명"
}
variable "project_id" {
  type        = string
  description = "GCP 프로젝트 ID"
}
variable "region" {
  type        = string
}
variable "gke_service_account_name" {
  description = "GKE 노드 서비스 계정 이름"
  type        = string
  default     = "gke-node-sa"
}
variable "credentials_path" {
  description = "GCP 인증 정보 JSON 파일 경로"
  type        = string
}