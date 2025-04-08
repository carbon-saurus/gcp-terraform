# Google Cloud에서 글로벌 정적 IP 주소를 생성
resource "google_compute_global_address" "ingress_static_ip" {
  project = var.project_id
  name = "${var.project}-${var.env}-static-ip"
}

# module "external_dns_gke" {
#   source  = "terraform-iaac/external-dns/kubernetes"
#   version = "1.3.2"
#   namespace = "kube-system"
#   create_namespace = false

#   dns          = [google_dns_managed_zone.dev_carbontrack_app_zone.name] # GCP Cloud DNS managed zone name
#   dns_provider = "google"
# }

# GCP Cloud DNS에서 퍼블릭 DNS 관리 영역(Managed Zone)을 생성
resource "google_dns_managed_zone" "dev_carbontrack_app_zone" {
  project      = var.project_id
  name         = var.dns_zone_name           #"dev-carbontrack-app-zone" # Managed Zone 이름 (원하는 이름으로 변경 가능)
  dns_name     = var.dns_domain_name    #"dev.carbontrack.app."    # 도메인 이름 (반드시 крапка(`.`)으로 끝나야 함)
  description  = "Managed zone for carbonsaurus.net" # 설명 (선택 사항)
  visibility   = "public" # 공개 영역으로 설정

  labels = {
    env = var.env
    project = var.project
  }
}

# 메인 도메인 A 레코드 생성
resource "google_dns_record_set" "dev_carbontrack_app_a_record" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
  name         = var.dns_domain_name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]

  depends_on = [
    google_compute_global_address.ingress_static_ip,
    google_dns_managed_zone.dev_carbontrack_app_zone
  ]
}

# 서브도메인 A 레코드 생성 (dev.carbonsaurus.net)
resource "google_dns_record_set" "dev_env_record" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
  name         = "${var.env}.${var.dns_domain_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]

  depends_on = [
    google_compute_global_address.ingress_static_ip,
    google_dns_managed_zone.dev_carbontrack_app_zone
  ]
}

# dev-api 서브도메인 A 레코드 생성
resource "google_dns_record_set" "dev_api" {
  name         = "dev-api.${var.dns_domain_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
  depends_on = [
    google_compute_global_address.ingress_static_ip,
    google_dns_managed_zone.dev_carbontrack_app_zone
  ]
}

# dev-admin 서브도메인 A 레코드 생성
resource "google_dns_record_set" "dev_admin" {
  name         = "dev-admin.${var.dns_domain_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
  depends_on = [
    google_compute_global_address.ingress_static_ip,
    google_dns_managed_zone.dev_carbontrack_app_zone
  ]
}

# # new-dev 서브도메인 A 레코드 생성 (더 이상 사용하지 않음)
# resource "google_dns_record_set" "new_dev" {
#   name         = "new-dev.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
#   
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.dev_carbontrack_app_zone
#   ]
# }

# # new-dev-admin 서브도메인 A 레코드 생성 (더 이상 사용하지 않음)
# resource "google_dns_record_set" "new_dev_admin" {
#   name         = "new-dev-admin.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
#   
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.dev_carbontrack_app_zone
#   ]
# }