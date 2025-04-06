# module/cloudsql/main.tf
resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_sql_database_instance" "carbontrack_db" {
  name             = var.db_instance_name
  region           = var.region
  database_version = var.db_version
  
  deletion_protection = false
  depends_on = [
    google_project_service.sqladmin,
    # google_service_networking_connection.private_connection
  ]

  settings {
    tier            = var.db_instance_type
    disk_type       = var.db_disk_type

    disk_autoresize = true
    disk_autoresize_limit = 0  # 0은 제한 없음

    ip_configuration {
      # Public IP를 사용하지 않을 경우
      # ipv4_enabled    = false
      ipv4_enabled    = true
      private_network = var.network_id
      # allocated_ip_range = "${var.project}-${var.env}-peering-private-ip"

      authorized_networks {
        name  = "office-access"
        value = var.office_ip
      }
    }

    ## 백업
    # backup_configuration {
    #   enabled = true
    #   point_in_time_recovery_enabled = true
    #   start_time = "03:00"                  # 백업 시작 시간 (UTC)
    #   transaction_log_retention_days = 7    # 트랜잭션 로그 보관 기간 (7일)
    # }

  }
}

###################################
############ 복제본 설정 ###########
######### 필요시 주석 제거 #########
###################################
## 생성할 복제본 수
# variable "replica_count" { 
#   type = number 
#   default = 1 
# } 

# resource "google_sql_database_instance" "replica" {
#   # count 또는 for_each 사용하여 여러 복제본 생성 가능
#   count = var.replica_count # 예: replica_count=1 이면 1개 생성

#   name             = "${google_sql_database_instance.carbontrack_db.name}-replica-${count.index}"
#   project          = google_sql_database_instance.carbontrack_db.project
#   region           = google_sql_database_instance.carbontrack_db.region
#   database_version = google_sql_database_instance.carbontrack_db.database_version
#   # 복제본은 원본 인스턴스를 참조
#   master_instance_name = google_sql_database_instance.carbontrack_db.name

#   # 복제본은 별도의 설정 블록을 가짐 (일부 설정은 원본을 따름)
#   settings {
#     tier = var.db_instance_type # 복제본의 등급 (원본과 같거나 다를 수 있음)
#     # 복제본의 가용 영역 (원본과 다른 Zone 권장)
#     availability_type = "ZONAL"

#     # 복제본의 디스크 설정 (일반적으로 원본과 유사하게 설정)
#     disk_autoresize = true
#     disk_type       = var.db_disk_type

#     # 복제본의 IP 구성 (일반적으로 원본과 동일한 네트워크 사용)
#     ip_configuration {
#       ipv4_enabled    = false
#       private_network = var.network_id
#       # 복제본에 직접 접근해야 하는 경우 authorized_networks 설정 가능
#     }

#     # 복제본은 자체 백업 설정을 가질 수 없음 (원본의 백업을 사용)
#     backup_configuration {
#       enabled = false
#     }
#   }

#   # 복제본은 원본 인스턴스가 준비된 후에 생성되어야 함
#   depends_on = [
#     google_sql_database_instance.carbontrack_db,
#   ]
# }

# 데이터베이스 사용자 생성
resource "google_sql_user" "users" {
  lifecycle {
    prevent_destroy = false
  }
  name     = var.db_user
  instance = google_sql_database_instance.carbontrack_db.name
  password = var.db_password
}

# 데이터베이스 생성
resource "google_sql_database" "dev_database" {
  name     = var.db_name
  instance = google_sql_database_instance.carbontrack_db.name
}
# resource "google_sql_database" "test_database" {
#   name     = var.test_db_name
#   instance = google_sql_database_instance.carbontrack_db.name
# }