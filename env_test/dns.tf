# Google Cloud에서 글로벌 정적 IP 주소를 생성
# resource "google_compute_global_address" "ingress_static_ip" {
#   project = var.project_id
#   name = "${var.project}-${var.env}-static-ip"
# }

# 이미 생성된 글로벌 정적 IP 주소를 참조
data "google_compute_global_address" "ingress_static_ip" {
  project = var.project_id
  name = "${var.project}-${var.env}-static-ip"
}

# module "external_dns_gke" {
#   source  = "terraform-iaac/external-dns/kubernetes"
#   version = "1.3.2"
#   namespace = "kube-system"
#   create_namespace = false

#   dns          = [google_dns_managed_zone.test_carbontrack_app_zone.name] # GCP Cloud DNS managed zone name
#   dns_provider = "google"
# }

# 기존 DNS 관리 영역 데이터 가져오기
data "google_dns_managed_zone" "test_carbontrack_app_zone" {
  project = var.project_id
  name    = var.dns_zone_name         # "carbonsaurus-net-zone"
}

# 메인 도메인 A 레코드 생성 (test.carbonsaurus.net)
resource "google_dns_record_set" "test_carbontrack_app_a_record" {
  project      = var.project_id
  managed_zone = data.google_dns_managed_zone.test_carbontrack_app_zone.name
  name         = "${var.env}.${var.dns_domain_name}"  # test.carbonsaurus.net
  type         = "A"
  ttl          = 300
  rrdatas      = [data.google_compute_global_address.ingress_static_ip.address]

  depends_on = [
    data.google_compute_global_address.ingress_static_ip
  ]
}

# test-api 서브도메인 A 레코드 생성
resource "google_dns_record_set" "test_api" {
  name         = "test-api.${var.dns_domain_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.test_carbontrack_app_zone.name
  rrdatas      = [data.google_compute_global_address.ingress_static_ip.address]
  
  depends_on = [
    data.google_compute_global_address.ingress_static_ip
  ]
}

# test-admin 서브도메인 A 레코드 생성
resource "google_dns_record_set" "test_admin" {
  name         = "test-admin.${var.dns_domain_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.test_carbontrack_app_zone.name
  rrdatas      = [data.google_compute_global_address.ingress_static_ip.address]
  
  depends_on = [
    data.google_compute_global_address.ingress_static_ip
  ]
}

# 새 URL 패턴으로 변경: test.carbonsaurus.net/track
# 기존 독립 도메인 코드는 주석 처리
# track-api 서브도메인 A 레코드
# resource "google_dns_record_set" "track_api" {
#   name         = "track-api.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.test_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
#   
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.test_carbontrack_app_zone
#   ]
# }

# account-api 서브도메인 A 레코드
# resource "google_dns_record_set" "account_api" {
#   name         = "account-api.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.test_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
#   
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.test_carbontrack_app_zone
#   ]
# }

# scrap-api 서브도메인 A 레코드
# resource "google_dns_record_set" "scrap_api" {
#   name         = "scrap-api.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.test_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
#   
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.test_carbontrack_app_zone
#   ]
# }

# new-dev 서브도메인 A 레코드 생성 (더 이상 사용하지 않음)
# resource "google_dns_record_set" "new_dev" {
#   name         = "new-dev.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = data.google_dns_managed_zone.test_carbontrack_app_zone.name
#   rrdatas      = [data.google_compute_global_address.ingress_static_ip.address]
#   
#   depends_on = [
#     data.google_compute_global_address.ingress_static_ip
#   ]
# }

# new-dev-admin 서브도메인 A 레코드 생성 (더 이상 사용하지 않음)
# resource "google_dns_record_set" "new_dev_admin" {
#   name         = "new-dev-admin.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = data.google_dns_managed_zone.test_carbontrack_app_zone.name
#   rrdatas      = [data.google_compute_global_address.ingress_static_ip.address]
#   
#   depends_on = [
#     data.google_compute_global_address.ingress_static_ip
#   ]
# }