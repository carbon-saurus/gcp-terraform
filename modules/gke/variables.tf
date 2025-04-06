variable "project_id" {
  type = string
}

variable "project" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "zones" {
  type = list(string)
  default = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "owner" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "master_ipv4_cidr_block" {
  type    = string
  default = "172.16.0.0/28"
}

variable "authorized_networks" {
  type    = list(string)
  default = []
}

variable "pod_range_name" {
  type    = string
  default = "pod-ip-range"
}

variable "svc_range_name" {
  type    = string
  default = "service-ip-range"
}

variable "master_machine_type" {
  type    = string
  default = "e2-medium"
}
variable "node_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "master_disk_size_gb" {
  type    = number
  default = 30
}

variable "node_disk_size_gb" {
  type    = number
  default = 30
}

variable "node_disk_type" {
  type    = string
  default = "pd-standard"
}

variable "initial_node_count" {
  type    = number
  default = 1
}

variable "min_node_count" {
  type    = number
  default = 1
}

variable "max_node_count" {
  type    = number
  default = 5
}

variable "gke_service_account" {
  type = string
}

variable "ssh_user" {
  type = string
}

variable "ssh_pub_key" {
  type = string
}