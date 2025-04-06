# resource "google_compute_global_address" "ingress_static_ip" {
#   project = var.project_id
#   name = "${var.project}-${var.env}-static-ip"
# }

# module "external_dns_gke" {
#   source  = "terraform-iaac/external-dns/kubernetes"
#   version = "1.3.2"
#   namespace = "kube-system"
#   create_namespace = false

#   dns          = [google_dns_managed_zone.dev_carbontrack_app_zone.name] # GCP Cloud DNS managed zone name
#   dns_provider = "google"
# }

# resource "google_dns_managed_zone" "test_carbontrack_app_zone" {
#   project      = var.project_id
#   name         = var.dns_zone_name           #"dev-carbontrack-app-zone" # Managed Zone 이름 (원하는 이름으로 변경 가능)
#   dns_name     = var.dns_domain_name    #"dev.carbontrack.app."    # 도메인 이름 (반드시 крапка(`.`)으로 끝나야 함)
#   description  = "Managed zone for carbonsaurus.net" # 설명 (선택 사항)
#   visibility   = "public" # 공개 영역으로 설정

#   labels = {
#     env = var.env
#     project = var.project
#   }
# }

# # Main Domain A Record
# resource "google_dns_record_set" "test_carbontrack_app_a_record" {
#   project      = var.project_id
#   managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
#   name         = var.dns_domain_name
#   type         = "A"
#   ttl          = 300
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]

#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.dev_carbontrack_app_zone
#   ]
# }

# scrap-api sub domain record set
# resource "google_dns_record_set" "scrap_api" {
#   name         = "scrap-api.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.dev_carbontrack_app_zone
#   ]
# }

# track-api sub domain record set
# resource "google_dns_record_set" "track_api" {
#   name         = "track-api.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.dev_carbontrack_app_zone
#   ]
# }

# account-api sub domain record set
# resource "google_dns_record_set" "account_api" {
#   name         = "account-api.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.dev_carbontrack_app_zone
#   ]
# }

# new-dev sub domain record set
# resource "google_dns_record_set" "new_dev" {
#   name         = "new-dev.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.dev_carbontrack_app_zone
#   ]
# }

# new-dev-admin sub domain record set
# resource "google_dns_record_set" "new_dev_admin" {
#   name         = "new-dev-admin.${var.dns_domain_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.dev_carbontrack_app_zone.name
#   rrdatas      = [google_compute_global_address.ingress_static_ip.address]
  
#   depends_on = [
#     google_compute_global_address.ingress_static_ip,
#     google_dns_managed_zone.dev_carbontrack_app_zone
#   ]
# }