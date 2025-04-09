# variables.tf

variable "project" {
  description = "GCP 프로젝트명"
  type        = string
}
variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
}

variable "owner" {
  description = "GCP Project Owner"
  type        = string 
}

variable "region" {
  description = "GCP 리전"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP 존"
  type        = string
  default     = "us-central1-a"
}

# variable "cluster_name" {
#   description = "GKE 클러스터 이름"
#   type        = string
#   default     = "my-gke-cluster"
# }

# variable "node_count" {
#   description = "노드 풀의 노드 수"
#   type        = number
#   default     = 2
# }

# variable "node_machine_type" {
#   description = "노드의 머신 타입"
#   type        = string
#   default     = "e2-medium"
# }

# variable "node_disk_type" {
#   description = "노드의 Disk 타입"
#   type        = string
#   default     = "pd-standard"
# }

# variable "node_service_account_name" {
#   description = "GKE 노드 서비스 계정 이름"
#   type        = string
#   default     = "gke-node-sa"
# }

variable "db_instance_name" {
  description = "Cloud SQL 인스턴스 이름"
  type        = string
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "db_user" {
  description = "데이터베이스 사용자 이름"
  type        = string
  default     = "testuser"
}

variable "db_password" {
  description = "데이터베이스 사용자 비밀번호"
  type        = string
}

variable "db_instnace_type" {
  description = "데이터베이스 Tier"
  type        = string
  default     = "db-custom-2-12288"
  # default     = "db-custom-2-16384"
}
variable "db_version" {
  type    = string
  default = "POSTGRES_15"
}

variable "domain_name" {
  description = "사용할 도메인 이름 (예: 'dev.carbontrack.app')"
  type        = string
}

variable "credentials_path" {
  description = "GCP 인증 정보 JSON 파일 경로"
  type        = string
}

variable "applications" {
  type = list(string)
}

variable "env" {
  type = string
}

# office ip
variable "office_ip" {
  description = "오피스 IP 주소 (예: '58.123.54.42/32')"
  type        = string
}

# developer ips
variable "developer_ips" {
  type = list(string)
  default = [
    "165.225.229.31/32"
  ]
}

# developer ids
variable "developer_ids" {
  description = "List of developer usernames."
  type        = list(string)
  default = [
    "jihyuk.kim",
    "sikim",
    "tk.kim",
    "jinhwa.lee",
    "ysun7",
    "slowkim",
    "kkardd",
    "youngbae_kwon",  # 삭제 필요
  ]
}

# dns zone name
variable "dns_zone_name" {
  type = string
  default = "carbonsaurus-net-zone"
}

# dns domain name
variable "dns_domain_name" {
  type = string
  default = "carbonsaurus.net."
}

# 변수 정의 (variables.tf)
variable "vm_configs" {
  type = map(object({
    instance_name   = string  # VM 인스턴스 이름
    machine_type    = string  # VM 머신 타입
    zone            = string  # VM이 생성될 영역
    boot_disk_image = string  # VM 부팅 디스크 이미지
    boot_disk_size  = number  # VM 부팅 디스크 크기
    boot_disk_type  = string  # VM 부팅 디스크 타입
    install_gcloud  = bool    # gcloud 설치 여부
    external_ip     = optional(bool, false) # 선택 사항, 기본값 false, 외부 IP 할당 여부
  }))
  default = {
    bastion_prod = {
      instance_name   = "bastion-prod"
      machine_type    = "e2-micro"
      zone            = "asia-northeast3-a" # 또는 local.zones[-1]
      boot_disk_image = "ubuntu-os-cloud/ubuntu-2005-lts"
      boot_disk_size  = 10
      boot_disk_type  = "pd-standard"
      install_gcloud  = true
      external_ip     = true
    }
  }
}
