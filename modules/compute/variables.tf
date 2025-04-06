variable "project" {
  description = "GCP 프로젝트명"
  type        = string
}
variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
}

variable "env" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}
variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "boot_disk_image" {
  type    = string
}

variable "boot_disk_size" {
  type    = number
}

variable "boot_disk_type" {
  type    = string
}

variable "external_ip" {
  type    = bool
  default = false
}

variable "ssh_pub_key" {
  type = string
}

variable "install_gcloud" {
  type    = bool
}

variable "developer_ids" {
  type    = list(string)
}
