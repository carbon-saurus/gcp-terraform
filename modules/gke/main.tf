resource "google_container_cluster" "primary" {
  name                     = "${var.cluster_name}"
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = var.initial_node_count

  network                 = var.network_id
  subnetwork              = var.subnet_id

  deletion_protection       = false

  #enable_autopilot          = false
  enable_tpu                = false

  node_locations            = var.zones

  # 클러스터에 대한 Cloud Logging 및 Cloud Monitoring을 활성화합니다.
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # 클러스터에 대한 네트워크 정책을 활성화합니다.
  # network_policy {
  #   enabled = true
  # }

  # 클러스터에 대한 태그를 추가합니다.
  resource_labels = {
    "karpenter_discovery" = "${var.cluster_name}"
  }
  
  node_config {
    machine_type = var.master_machine_type
    disk_size_gb = var.master_disk_size_gb

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    tags = ["${var.cluster_name}"]
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value
        display_name = "Allow access from subnet"
      }
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.svc_range_name
  }

#   deletion_protection = false

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # lifecycle {
  #   # prevent_destroy = true    # prevent cluster deletion
  #   prevent_destroy = false     # cluster deletion
  # }

  # lifecycle {
    # ignore_changes = [
      # addons_config,
    # ]
  # }

  lifecycle {
    ignore_changes = [
      node_config[0].metadata,
      node_config[0].oauth_scopes,
      node_config[0].tags,
    ]
  }
}

resource "google_container_node_pool" "cluster-nodes" {
  name       = "${var.project}-${var.env}-node-pool"
  cluster    = google_container_cluster.primary.id
  node_locations   = var.zones
  
  node_count = var.initial_node_count

  node_config {
    machine_type    = var.node_machine_type
    disk_size_gb    = var.node_disk_size_gb
    disk_type       = var.node_disk_type
    
    service_account = var.gke_service_account

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/sqlservice.admin",
    ]

    labels = {
      environment = var.env
    }

    metadata = {
        "ssh-keys"               = "${var.owner}:${var.ssh_pub_key}"
        "block-project-ssh-keys" = "false"
        disable-legacy-endpoints = "true"
    }
    
    tags = ["${var.project}-${var.env}-gke-node"]
  }

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  depends_on = [google_container_cluster.primary]


}

resource "null_resource" "get_gke_credentials" {
  depends_on = [ google_container_cluster.primary ]

  # triggers = {
  #   cluster_endpoint = google_container_cluster.primary.endpoint
  #   cluster_id = google_container_cluster.primary.id
  # }
  provisioner "local-exec" {
     command = "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.region} --project ${var.project_id}"
  #   command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project_id} && echo 'Credentials fetched successfully' > ${path.module}/credentials.txt"
  
  }
}

resource "null_resource" "node_pool_ready" {
  depends_on = [google_container_node_pool.cluster-nodes]

  triggers = {
    node_pool_name = google_container_node_pool.cluster-nodes.name
  }
}

# # 실행 결과 확인을 위한 output 추가
# output "credentials_status" {
#   value = fileexists("${path.module}/credentials.txt") ? "Credentials fetched successfully" : "Credentials fetch failed"
# }

# output "cluster_info" {
#   value = fileexists("${path.module}/cluster-info.txt") ? file("${path.module}/cluster-info.txt") : "Cluster info not available"
# }

# Fargate 네임스페이스 생성 (격리된 환경 제공)
# resource "kubernetes_namespace" "fargate_namespace" {
#   depends_on = [
#     google_container_cluster.primary,
#     google_container_node_pool.cluster-nodes,
#     null_resource.get_gke_credentials
#   ]
  
#   metadata {
#     name = "fargate"
#   }
# }

# # Fargate 네트워크 정책 생성 (인바운드 트래픽 제한)
# resource "kubernetes_network_policy" "fargate_network_policy" {
#   depends_on = [ kubernetes_namespace.fargate_namespace ]
#   metadata {
#     name      = "fargate-network-policy"
#     namespace = kubernetes_namespace.fargate_namespace.metadata[0].name
#   }
#   spec {
#     pod_selector {
#       match_labels = {
#         "app" = "fargate-app"  # 이 레이블을 가진 포드에 적용
#       }
#     }
#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             "name" = "kube-system"  # kube-system 네임스페이스의 포드만 허용
#           }
#         }
#       }
#     }
#     policy_types = ["Ingress"]  # 인바운드 트래픽에만 적용
#   }
# }
