variable "project_id" {
  type = string
}
variable "project" {
  type = string
}
variable "region" {
  type = string
}

variable "zone" {
  type = string
  default = "asia-northeast3-a"
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

variable "credentials_path" {
  description = "GCP 인증 정보 JSON 파일 경로"
  type        = string
}

variable "env" {
  type = string
}

variable "owner" {
  type = string
}
variable "domain_name" {
  type = string
}

# 서비스 계정 변수 - 일관된 참조 제공
variable "gke_service_account" {
  description = "GKE 서비스 계정 이메일"
  type        = string
  default     = "gke-sa@re100-dev.iam.gserviceaccount.com"
}

variable "gcr_service_account" {
  description = "GCR 서비스 계정 이메일"
  type        = string
  default     = "gcr-sa@re100-dev.iam.gserviceaccount.com"
}

variable "cloud_sql_proxy_service_account" {
  description = "Cloud SQL Proxy 서비스 계정 이메일"
  type        = string
  default     = "cloud-sql-proxy-sa@re100-dev.iam.gserviceaccount.com"
}

variable "external_secret_service_account" {
  description = "External Secret 서비스 계정 이메일"
  type        = string
  default     = "external-secret-sa@re100-dev.iam.gserviceaccount.com"
}

# variable "db_instance_name" {
  # type = string
# }

variable "applications" {
  type = list(string)
}

# variable "gcr_password" {
#   description = "gcr password or ecr login password"
#   type = string
# }

variable "ksa_name" {
  type = string
  default ="external-secrets-sa"
}

variable "username" {
  type = string
  default = "_json_key"
}
variable "gcr_server" {
  type = string
  default = "https://us-docker.pkg.dev"
}

variable "asia_gcr_server" {
  type = string
  default = "asia-northeast3-docker.pkg.dev"
}
variable "secret_name" {
  type = string
  default = "gcr-secret"
}
# variable "namespace" {
#   type = string
# }

variable "email" {
  type = string
  default = "gcr-sa@re100-dev.iam.gserviceaccount.com"
}
# variable "password" {
#   type = string
# }

variable "dns_zone_name" {
  type = string
  default = "re100-dev-net-zone"
}

variable "dns_domain_name" {
  type = string
  default = "re100-dev.carbonsaurus.net."
  
}

variable "sub_domain" {
  type = string
  default = "dev"
}