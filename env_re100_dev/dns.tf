# Google Cloud에서 글로벌 정적 IP 주소를 생성
resource "google_compute_global_address" "ingress_static_ip" {
  project = var.project_id
  name = "${var.project}-${var.env}-static-ip"
}

# 이미 생성된 글로벌 정적 IP 주소를 참조 (주석 처리)
# data "google_compute_global_address" "ingress_static_ip" {
#   project = var.project_id
#   name = "${var.project}-${var.env}-static-ip"
# }

# module "external_dns_gke" {
#   source  = "terraform-iaac/external-dns/kubernetes"
#   version = "1.3.2"
#   namespace = "kube-system"
#   create_namespace = false

#   dns          = [google_dns_managed_zone.re100_dev_carbontrack_app_zone.name] # GCP Cloud DNS managed zone name
#   dns_provider = "google"
# }

# 기존 DNS 관리 영역 데이터 가져오기
data "google_dns_managed_zone" "re100_dev_carbontrack_app_zone" {
  project = var.project_id
  name    = var.dns_zone_name         # "carbonsaurus-net-zone"
}

# 루트 도메인 A 레코드 생성 (carbonsaurus.net)
resource "google_dns_record_set" "root_domain" {
  project      = var.project_id
  managed_zone = data.google_dns_managed_zone.re100_dev_carbontrack_app_zone.name
  name         = var.dns_domain_name  # carbonsaurus.net.
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]

  depends_on = [
    google_compute_global_address.ingress_static_ip
  ]
}

# 메인 도메인 A 레코드 생성 (re100_dev.carbonsaurus.net)
resource "google_dns_record_set" "re100_carbontrack_app_a_record" {
  project      = var.project_id
  managed_zone = data.google_dns_managed_zone.re100_dev_carbontrack_app_zone.name
  name         = "re100.${var.dns_domain_name}"  # re100.carbonsaurus.net
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]

  depends_on = [
    google_compute_global_address.ingress_static_ip
  ]
}

# api 서브도메인 A 레코드 생성
resource "google_dns_record_set" "re100_eps_api" {
  name         = "api.${var.dns_domain_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.re100_dev_carbontrack_app_zone.name
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
  depends_on = [
    google_compute_global_address.ingress_static_ip
  ]
}

# admin 서브도메인 A 레코드 생성
resource "google_dns_record_set" "re100_eps_admin" {
  name         = "admin.${var.dns_domain_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.re100_dev_carbontrack_app_zone.name
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
  depends_on = [
    google_compute_global_address.ingress_static_ip
  ]
}
