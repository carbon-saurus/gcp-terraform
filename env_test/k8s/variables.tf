variable "project_id" {
  type = string
}
variable "project" {
  type = string
}
variable "region" {
  type = string
}

# variable "cluster_name" {
  # type = string
# }

# variable "zone" {
  # type = string
# }

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
  default = "gcr-sa@carbonsaurus-dev.iam.gserviceaccount.com"
}
# variable "password" {
#   type = string
# }

variable "dns_zone_name" {
  type = string
  default = "carbonsaurus-net-zone"
}

variable "dns_domain_name" {
  type = string
  default = "carbonsaurus.net."
  
}

variable "sub_domain" {
  type = string
  default = "test"
}