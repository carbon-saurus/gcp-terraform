
# 1. 인바운드 (Ingress) 룰 1: VPC CIDR에서 SSH (TCP 22) 허용
resource "google_compute_firewall" "ingress_ssh" {
  name       = "${var.project}-${var.env}-ingress-ssh"
  network    = var.network_id
  direction  = "INGRESS"
  priority   = 1000

  # 이 룰은 target_tags가 부여된 인스턴스에 적용됩니다.
  target_tags = ["${var.project}-${var.env}-general-fw"]

  description   = "Allow SSH (TCP 22) from VPC CIDR"
  source_ranges = [
    var.network_cidr  # 예: "10.0.0.0/16"
  ]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# 2. 인바운드 (Ingress) 룰 2: 다른 VPC (Remote State에서 가져온 CIDR)에서 모든 트래픽 허용
resource "google_compute_firewall" "ingress_vpc_all" {
  name       = "${var.project}-${var.env}-ingress-vpc"
  network    = var.network_id
  direction  = "INGRESS"
  priority   = 1000

  target_tags = ["${var.project}-${var.env}-general-fw"]

  description = "Allow all traffic from remote VPC CIDR"
  # 외부(예: DevOps 환경)에서 관리되는 VPC CIDR을 remote state로 참조합니다.
  source_ranges = [
    # data.terraform_remote_state.devops.outputs.network_cidr
    var.network_cidr
  ]

  allow {
    protocol = "all"
  }
}

# 3. 인바운드 (Ingress) 룰 3: 사무실 IP에서 모든 트래픽 허용
resource "google_compute_firewall" "allow_office_access" {
  name    = "allow-${var.env}-office-access"
  network = var.network_id
  # allow {
  #   protocol = "all"
  # }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "5432"] # 필요한 포트만 허용
  }
  direction    = "INGRESS"
  priority     = 1000
  source_ranges = [var.office_ip, "0.0.0.0/0"]    # var.office_ip는 예: "203.0.113.45/32" 형태여야 합니다.
  
  target_tags = ["${var.project}-${var.env}-general-fw"]

}

# 4. 아웃바운드 (Egress) 룰: 모든 아웃바운드 트래픽 허용
resource "google_compute_firewall" "egress_all" {
  name       = "${var.project}-${var.env}-egress-all"
  network    = var.network_id
  direction  = "EGRESS"
  priority   = 1000

  target_tags = ["${var.project}-${var.env}-general-fw"]

  description        = "Allow all outbound traffic"
  destination_ranges = [
    "0.0.0.0/0"
  ]

  allow {
    protocol = "all"
  }
}

# 5. Bastion VM에서 GKE 노드로 SSH (TCP 22) 허용
resource "google_compute_firewall" "bastion_to_gke_nodes" {
  name       = "${var.project}-${var.env}-bastion-to-gke"
  network    = var.network_id
  direction  = "INGRESS"
  priority   = 1000

  # GKE 노드에 부여할 태그
  target_tags = ["${var.project}-${var.env}-gke-node"]
  # bastion VM에 부여된 태그 (방화벽 출발 태그)
  source_tags = ["${var.project}-${var.env}-general-fw"]

  description = "Allow SSH (TCP 22) from Bastion VM to GKE nodes"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# 6. IAM 보안 정책: GKE 노드에 SSH 접속을 위한 IAP 보안 정책
resource "google_compute_firewall" "allow-ssh-iap" {
  name    = "allow-${var.env}-ssh-iap"
  network = var.network_id

  direction    = "INGRESS"
  priority     = 1000
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# 방화벽 규칙 생성
resource "google_compute_firewall" "allow_proxy_connection" {
  name    = "allow-${var.env}-proxy-connection"
  network = var.network_id
  # network = google_compute_network.carbon_network.self_link # VPC 네트워크

  allow {
    protocol = "tcp"
    ports    = ["3000", "3001", "8000", "8080"]
  }

  source_ranges = ["10.129.0.0/23"] # 프록시 전용 서브넷의 IP 범위
  # target_tags   = ["gke-internal-ilb"] # GKE 내부 Ingress에 의해 자동 생성되는 타겟 태그
  
  # depends_on = [ google_compute_subnetwork.proxy_only_subnet ]
}
