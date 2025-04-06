variable "project_id" {
  type = string
}
variable "region" {
  description = "GCP 리전"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP 존"
  type        = string
  default     = "asia-northeast3-a"
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "network_cidr" {
  type = string
}
variable "public_ip_cidr_range" {
  type = string
}
variable "private_ip_cidr_range" {
  type = string
}
variable "database_ip_cidr_range" {
  type = string
}

variable "office_ip" {
  type = string
}

variable "vpc_name" {
  type = string
  description = "VPC Name"
  default = "gcp-vpc"
}

variable "cidr_block_vpc" {
  type = string
  description = "VPC CIDR Block"
  default = "10.0.0.0/16"
}

variable "cidr_block_internet_facing" {
  type = string
  description = "Internet Facing Subnet CIDR Block"
  default = "10.0.1.0/24"
}

variable "cidr_block_management" {
  type = string
  description = "Management Subnet CIDR Block"
  default = "10.0.2.0/24"
}

variable "cidr_block_internal_a" {
  type = string
  description = "Internal Subnet A CIDR Block"
  default = "10.0.3.0/24"
}

variable "cidr_block_internal_b" {
  type = string
  description = "Internal Subnet B CIDR Block"
  default = "10.0.4.0/24"
}