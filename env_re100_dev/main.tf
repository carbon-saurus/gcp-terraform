# 원격 상태 파일을 가져옵니다. 이 파일은 GCS 버킷에 저장된 Terraform 상태 파일입니다.
data "terraform_remote_state" "devops" {
  backend = "gcs"

  config = {
    bucket  = "re100-dev-devops-bucket"   # devops 관련 상태 정보가 저장된 GCS 버킷 이름
    prefix  = "terraform/dev/devops/terraform.tfstate"       # 상태 파일 경로(prefix)
  }
}

# 로컬 변수 정의
locals {
  applications_map = { for idx, app in var.applications : app => app }
  # 클러스터 이름 정의
  cluster_name     = "${var.project}-${var.env}-cluster"
  # 네트워크 CIDR 블록 정의
  network_cidr     = "10.0.0.0/16"
  # 사무실 IP 주소 정의
  # office_ip        = "58.151.93.2/32"
  office_ip        = "165.225.229.31/32"
  region           = var.region

  # 사용 가능한 영역 정의
  # zones            = slice(data.google_compute_zones.available.names, 0, 3)
  # zones = ["${var.region}-a", "${var.region}-b", "${var.region}-c"]
  zones = ["${var.region}-a"]

 # 서브넷 CIDR 블록 정의
  public_subnets    = [for i in range(length(local.zones)) : cidrsubnet(local.network_cidr, 8, i)]
  private_subnets   = [for i in range(length(local.zones)) : cidrsubnet(local.network_cidr, 8, i + 3)]
  database_subnets  = [for i in range(length(local.zones)) : cidrsubnet(local.network_cidr, 8, i + 6)]

  # IP 범위 이름 정의
  pods_range_name        = "pod-ip-range"
  svc_range_name         = "service-ip-range"

  # 부팅 디스크 이미지 정의
  vm_boot_disk_image = "ubuntu-os-cloud/ubuntu-2004-lts"

  # 마스터 노드 설정
  master_machine_type = "e2-medium"
  master_disk_type    = "pd-standard" 
  master_disk_size_gb = 30
  
  # 노드 설정
  node_machine_type   = "e2-medium"
  node_disk_type      = "pd-standard"
  node_disk_size_gb   = 30
  initial_node_count  = 1
  min_node_count      = 1
  max_node_count      = 5

  # 데이터베이스 설정
  db_instance_type  = "db-custom-2-12288"
  db_version        = "POSTGRES_15"
  db_disk_type      = "PD-HDD"
  # db_disk_type      = "PD-SSD"
  
  # 서비스 계정 이메일 형식: [NAME]@[PROJECT_ID].iam.gserviceaccount.com
  gke_service_account = "gke-sa@${var.project_id}.iam.gserviceaccount.com"
  gcr_service_account = "gcr-sa@${var.project_id}.iam.gserviceaccount.com"
  cloud_sql_proxy_service_account = "cloud-sql-proxy-sa@${var.project_id}.iam.gserviceaccount.com"
  external_secret_service_account = "external-secret-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Common 리모트 상태 파일을 가져옵니다. 이 파일은 GCS 버킷에 저장된 Terraform 상태 파일입니다
# 현재는 상태 파일이 없으므로 주석 처리합니다.
# data "terraform_remote_state" "base_iam" {
#   backend = "gcs" 
#   config = {
#     bucket = "re100-dev-devops-bucket"  
#     prefix = "terraform/common/gcp/re100_dev.tfstate"
#   } 
# }

# IAM 서비스 계정 및 역할 생성
module "iam" {
  source = "../modules/iam"

  project_id = var.project_id
  gke_node_sa_email = local.gke_service_account
  gcr_sa_email      = local.gcr_service_account
  cloud_sql_proxy_sa_email = local.cloud_sql_proxy_service_account
  external_secret_sa_email = local.external_secret_service_account

  # region     = data.google_client_config.current.region
}

# Google Cloud에서 사용 가능한 영역을 가져옵니다.
# data "google_compute_zones" "available" {
#   region = var.region

#   depends_on = [ module.iam ]
# }

# VPC 네트워크 생성 모듈
module "network" {
  source = "../modules/network"

  vpc_name      = "${var.project}-${var.env}-vpc"
  project_id    = var.project_id
  project       = var.project
  env           = var.env
  network_cidr  = local.network_cidr
  office_ip     = local.office_ip

  public_ip_cidr_range   = local.public_subnets[0]
  private_ip_cidr_range  = local.private_subnets[0]
  database_ip_cidr_range = local.database_subnets[0]

  # depends_on = [ module.iam ]
}

# Firewall 생성
module "firewall" {
  source = "../modules/firewall"

  project      = var.project
  env          = var.env
  office_ip    = local.office_ip
  network_id   = module.network.network_id
  network_cidr = local.network_cidr

  # depends_on = [ module.iam ]
}

#################################################
### Node용 SSH 키 생성 및 Secret Manager에 저장 #######
#################################################
resource "tls_private_key" "node_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "node_key_secret" {
  source = "../modules/secret_manager"

  secret_id   = "${var.project}-${var.env}-node-key"
  secret_data = tls_private_key.node_key.private_key_pem

  # depends_on = [ module.iam ]
}

# SSH 키를 PEM 형식으로 변환하여 로컬 파일로 저장합니다. (선택 사항)
resource "local_file" "node_key_pem" {
  filename = "${var.project}-${var.env}-node.pem"
  content  = tls_private_key.node_key.private_key_pem
}

##############################
### Bastion 서버 (Compute Instance) ###
##############################
# 모듈 호출 (main.tf)
module "vms" {
  source = "../modules/compute"
  for_each = var.vm_configs                   # var.vm_configs에 정의된 VM 설정을 반복하여 VM을 생성합니다.

  project_id      = var.project_id            # 프로젝트 ID
  project         = var.project               # 프로젝트 이름
  env             = var.env                   # 환경 이름
  instance_name   = each.value.instance_name  # VM 인스턴스 이름
  machine_type    = each.value.machine_type   # VM 머신 타입
  boot_disk_image = local.vm_boot_disk_image  # 현재 사용 중인 방식: 로컬 변수에 정의된 부팅 디스크 이미지를 사용
  boot_disk_size  = each.value.boot_disk_size # 부팅 디스크 크기
  boot_disk_type  = each.value.boot_disk_type # 부팅 디스크 타입
  region          = var.region                # 리전
  zone            = each.value.zone           # 영역
  network_id      = module.network.network_id # 네트워크 ID
  subnet_id       = module.network.public_subnet_id # 또는 private subnet # 서브넷 ID (public 서브넷 사용)
  external_ip     = each.value.external_ip    # 외부 IP 할당 여부
  developer_ids      = var.developer_ids      # 개발자 ID 목록
  ssh_pub_key     = tls_private_key.node_key.public_key_openssh # SSH 공개 키
  install_gcloud  = each.value.install_gcloud # gcloud 설치 여부

  # depends_on = [ module.iam ]
}

##############################
# GKE 클러스터 생성
##############################
module "gke" {
  source = "../modules/gke"

  cluster_name = local.cluster_name           # 클러스터 이름
  project_id     = var.project_id             # 프로젝트 ID
  project     = var.project                   # 프로젝트 이름
  env         = var.env                       # 환경 이름
  region        = var.region                  # 리전
  zones        = local.zones                  # 영역 목록
  owner       = var.owner                     # 소유자
  network_id  = module.network.network_id     # 네트워크 ID
  subnet_id   = module.network.private_subnet_id # 서브넷 ID (private 서브넷 사용)
  
  authorized_networks = ["0.0.0.0/0", module.network.private_subnet_cidr, module.network.public_subnet_cidr] # 허용된 네트워크 목록 (모든 IP, private 서브넷, public 서브넷)

  gke_service_account = local.gke_service_account # GKE 서비스 계정
  
  master_machine_type   = local.master_machine_type # 마스터 노드 머신 타입
  master_disk_size_gb   = local.master_disk_size_gb # 마스터 노드 디스크 크기 (GB)
  # master_disk_type      = local.master_disk_type    # 마스터 노드 디스크 크기 (GB)

  node_machine_type     = local.node_machine_type   # 노드 머신 타입"
  node_disk_size_gb     = local.node_disk_size_gb   # 노드 디스크 크기 (GB)
  node_disk_type        = local.node_disk_type      # 노드 디스크 타입
  initial_node_count    = local.initial_node_count  # 초기 노드 개수
  min_node_count        = local.min_node_count      # 최소 노드 개수
  max_node_count        = local.max_node_count      # 최대 노드 개수

  ssh_user        = var.owner # SSH 사용자 이름
  ssh_pub_key     = tls_private_key.node_key.public_key_openssh # SSH 공개 키

  # depends_on = [ module.iam ]
}

# VPC Peering 생성 ##
module "vpc_peering" {
  source = "../modules/vpc_peering"

  project_id    = var.project_id
  project    = var.project
  env        = var.env
  network_id = module.network.network_id  # 네트워크 ID
}

##############################
# Cloud SQL 생성
##############################
module "cloudsql" {
  source = "../modules/cloudsql"

  project_id = var.project_id
  project    = var.project
  env        = var.env
  region     = var.region
  
  network_id        = module.network.network_id       # 네트워크 ID
  office_ip         = var.office_ip                   # 사무실 IP 주소
  db_password       = var.db_password                 # 데이터베이스 비밀번호
  db_instance_type  = local.db_instance_type          # 데이터베이스 인스턴스 타입
  db_version        = local.db_version                # 데이터베이스 버전
  db_disk_type      = local.db_disk_type              # 데이터베이스 디스크 타입
  db_name           = var.db_name                     # 데이터베이스 이름
  db_user           = var.db_user                     # 데이터베이스 사용자 이름
  db_instance_name  = "${var.project}-${var.env}-db"  # 데이터베이스 인스턴스 이름

  depends_on = [module.vpc_peering]
}