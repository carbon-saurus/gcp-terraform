# 기존 VPC 네트워크 정보 가져오기
# data "google_compute_network" "carbon_re_vpc" {
  # name = "${var.project}-${var.env}-vpc"  # 기존 VPC 네트워크 이름
  # project = var.project_id # 구글 클라우드 프로젝트 ID
# }

# # 프록시 전용 서브넷 생성
# resource "google_compute_subnetwork" "proxy_only_subnet" {
#   name          = "proxy-only-subnet"
#   ip_cidr_range = "10.129.0.0/23"
#   region        = var.region
#   network       = data.google_compute_network.carbon_re_vpc.self_link # VPC 네트워크
#   purpose       = "REGIONAL_MANAGED_PROXY"
#   role          = "ACTIVE"
# }

# # 방화벽 규칙 생성
# resource "google_compute_firewall" "allow_proxy_connection" {
#   name    = "allow-proxy-connection"
#   network = data.google_compute_network.carbon_re_vpc.self_link # VPC 네트워크

#   allow {
#     protocol = "tcp"
#     ports    = ["8081", "8080"]
#   }

#   source_ranges = ["10.129.0.0/23"] # 프록시 전용 서브넷의 IP 범위
#   # target_tags   = ["gke-internal-ilb"] # GKE 내부 Ingress에 의해 자동 생성되는 타겟 태그
  
#   depends_on = [ google_compute_subnetwork.proxy_only_subnet ]
# }

resource "google_project_service" "cert_manager_api" {
  project = var.project_id
  service = "certificatemanager.googleapis.com"
}

# Managed Certificate 생성
resource "kubernetes_manifest" "re100_dev_gke_cert" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "ManagedCertificate"
    "metadata" = {
      "name" = "re100-dev-gke-cert",
      "namespace" = var.project             
    }
    "spec" = {
      "domains" = [
        "www.${trimsuffix(var.dns_domain_name, ".")}",
        "${trimsuffix(var.dns_domain_name, ".")}",
        "api.${trimsuffix(var.dns_domain_name, ".")}",
        "admin.${trimsuffix(var.dns_domain_name, ".")}"
      ]
    }
  }

  depends_on = [ module.project_namespace ]
}

# Backend Config 설정
# resource "kubernetes_manifest" "backend_config" {
#   manifest = {
#     "apiVersion" = "cloud.google.com/v1"
#     "kind"       = "BackendConfig"
#     "metadata" = {
#       "name"      = "backend-config"
#       "namespace" = var.project
#     }
#     "spec" = {
#       "timeoutSec" = 30
#       "connectionDraining" = {
#         "drainingTimeoutSec" = 300
#       }
#       "healthCheck" = {
#         "checkIntervalSec" = 15
#         "timeoutSec"       = 5
#         "healthyThreshold" = 1
#         "port"            = 80
#         "type"            = "HTTP"
#         "requestPath"     = "/health"  # 헬스체크 엔드포인트
#       }
#     }
#   }
# }

###############
### ingress ###
###############
# # Ingress 리소스 생성
resource "kubernetes_ingress_v1" "re100-dev-gke-ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "re100-dev-gke-ingress"
    namespace = var.project
    annotations = {
      "kubernetes.io/ingress.class"                     = "gce"
      "networking.gke.io/managed-certificates"          = "re100-dev-gke-cert"
      "kubernetes.io/ingress.global-static-ip-name"     = google_compute_global_address.ingress_static_ip.name
      "ingress.kubernetes.io/force-ssl-redirect"        = "true" # HTTP -> HTTPS 리디렉션
    }
  }
  spec {
    rule {
      host = "api.${trimsuffix(var.dns_domain_name, ".")}"
      http {
        path {
          path      = "/eps"
          path_type = "Prefix"
          backend {
            service {
              name = "re100-eps-api-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_manifest.re100_dev_gke_cert,
  ]
}

# # 사설 Ingress 리소스 생성
# resource "kubernetes_ingress_v1" "re100-dev-gke-ingress-internal" {
#   wait_for_load_balancer = true
#   # depends_on = [ module.project_namespace ]
#   metadata {
#     name = "re100-dev-gke-ingress-internal"
#     namespace = var.project
#     annotations = {
#       "kubernetes.io/ingress.class" = "gce-internal" # 내부 로드 밸런서 사용
#     }
#   }
#   spec {
#     # ingress_class_name = "gce-internal" # 내부 로드 밸런서 사용
#     default_backend {
#       service {
#         name = "re100-dev-internal-service" # 내부 서비스 사용
#         port {
#           number = 80
#           # name = "http-internal"
#         }
#       }
#     }
    # rule {
    #   host = "re100-dev-rollout.carbontrack.app"
    #   http {
    #     path {
    #       path = "/*"
    #       backend {
    #         service {
    #           name = "argo-rollouts-dashboard"
    #           port {
    #             number = 3100
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    # rule {
    #   host = "re100-dev-mq.carbontrack.app"
    #   http {
    #     path {
    #       path    = "/*"
    #       backend {
    #         service {
    #           name = "re100-dev-rabbitmq-prom"
    #           port {
    #             number = 15692
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
#   }
#   depends_on = [kubernetes_service.re100_dev_internal_service]
# }

# Google Cloud에서 글로벌 정적 IP 주소를 생성
resource "google_compute_global_address" "ingress_static_ip" {
  project = var.project_id
  name = "${var.project}-${var.env}-static-ip"
  
  lifecycle {
    ignore_changes = [name]
  }
}

# 이미 생성된 글로벌 정적 IP 주소를 참조 (주석 처리)
# data "google_compute_global_address" "ingress_static_ip" {
#   project = var.project_id
#   name = "${var.project}-${var.env}-static-ip"
# }

