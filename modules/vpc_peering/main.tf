resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project}-${var.env}-peering-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24

  project    = var.project_id
  network       = var.network_id
  # address       = "10.100.10.0"
}

resource "google_service_networking_connection" "private_connection" {
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_compute_global_address.private_ip_address]
}