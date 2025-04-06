# VPC 네트워크 생성
resource "google_compute_network" "carbon_network" {
  name                    = "${var.vpc_name}"
  auto_create_subnetworks = false

}

# #############
# ### 서브넷 ###
# ############
# public-subnet 생성 (필요한 경우 CIDR 블록 지정)
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet-${var.env}"
  ip_cidr_range = var.public_ip_cidr_range
  region        = var.region
  network       = google_compute_network.carbon_network.self_link
}


# private-subnet 생성
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet-${var.env}"
  ip_cidr_range = var.private_ip_cidr_range
  region        = var.region
  network       = google_compute_network.carbon_network.self_link

  secondary_ip_range {
    range_name    = "pod-ip-range"
    ip_cidr_range = "10.10.0.0/16"
  }

  secondary_ip_range {
    range_name    = "service-ip-range"
    ip_cidr_range = "10.20.0.0/16"
  }
}

# database-subnet 생성
resource "google_compute_subnetwork" "database_subnet" {
  name          = "intra-subnet-${var.env}"
  ip_cidr_range = var.database_ip_cidr_range
  region        = var.region
  network       = google_compute_network.carbon_network.self_link
}

# 프록시 전용 서브넷 생성
resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "proxy-only-subnet-${var.env}"
  ip_cidr_range = "10.129.0.0/23"
  region        = var.region
  network       = google_compute_network.carbon_network.self_link # VPC 네트워크
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# ###############
# ### Cloud NAT ###
# ###############
resource "google_compute_address" "nat_ip" {
  name          = "${var.vpc_name}-nat-ip"
  address_type  = "EXTERNAL"
  # prefix_length = 28 # 필요한 경우 조정
  # network_tier = "PREMIUM"
  project      = var.project_id
  region        = var.region
}

# ###############
# ### Routing ###
# ###############
resource "google_compute_router" "nat_router" {
  name    = "${var.vpc_name}-nat-router"
  region  = var.region
  network = google_compute_network.carbon_network.self_link
  project = var.project_id
}

resource "google_compute_router_nat" "nat_config" {
  name                               = "${var.vpc_name}-nat-config"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ips                            = [google_compute_address.nat_ip.self_link]
  subnetwork {
    name                    = google_compute_subnetwork.private_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  project = var.project_id
}