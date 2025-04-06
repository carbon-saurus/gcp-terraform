variable "project_id" {
  type = string
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  type = string
}

variable "db_version" {
  type    = string
}

variable "db_instance_type" {
  type    = string
}

variable "db_disk_type" {
  type    = string
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "office_ip" {
  type = string
}

variable "db_instance_name" {
  description = "Cloud SQL 인스턴스 이름"
  type        = string
}

variable "db_name" {
  description = "데이터베이스 이름"
  type = string
}

variable "db_user" {
  description = "데이터베이스 사용자 이름"
  type        = string
}

variable "db_password" {
  description = "데이터베이스 사용자 비밀번호"
  type        = string
}