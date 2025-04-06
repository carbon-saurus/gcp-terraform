variable "project" {
  description = "GCP 프로젝트명"
  type        = string
}
variable "env" {
  type = string
}
variable "office_ip" {
  description = "오피스 IP 주소 (예: '58.123.54.42/32')"
  type        = string
}
variable "network_id" {
  type = string
}
variable "network_cidr" {
  type = string
  description = "네트워크 CIDR 범위"
}