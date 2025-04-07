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
resource "kubernetes_manifest" "carbon_re_gke_cert" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "ManagedCertificate"
    "metadata" = {
      "name" = "carbon-re-gke-cert",
      "namespace" = var.project             // 네임스페이스 추가
    }
    "spec" = {
      "domains" = [
        "${var.env}.${trimsuffix(var.dns_domain_name, ".")}"
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
resource "kubernetes_ingress_v1" "carbon_re_gke_ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "carbon-re-gke-ingress"
    namespace = var.project
    annotations = {
      "kubernetes.io/ingress.class"                     = "gce"
      "kubernetes.io/ingress.allow-http"                = "true"  # HTTP 트래픽 허용 여부 (true/false)
      "networking.gke.io/managed-certificates"          = "carbon-re-gke-cert"
      # "networking.gke.io/v1beta1.FrontendConfig"        = "carbon-re-fe-config"
      "kubernetes.io/ingress.global-static-ip-name"     = data.google_compute_global_address.ingress_static_ip.name
      "ingress.kubernetes.io/force-ssl-redirect"        = "true" # HTTP -> HTTPS 리디렉션
      # "beta.cloud.google.com/backend-config"            = "{\"/api/*\": \"carbon-re-be-config\"}"
      # "cloud.google.com/backend-config"                 = "{\"/api/*\": \"carbon-re-be-config\"}"
      # "kubernetes.io/ingress.allow-google-ip"          = "true"
    }
  }
  spec {
    rule {
      host = "${var.env}.${trimsuffix(var.dns_domain_name, ".")}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "carbon-re-service"
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/track/*"
          path_type = "Prefix"
          backend {
            service {
              name = "track-api-service"
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/account/*"
          path_type = "Prefix"
          backend {
            service {
              name = "account-api-service"
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/scrap/*"
          path_type = "Prefix"
          backend {
            service {
              name = "scrap-api-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    # rule {
    #   host = "new-dev-api.carbontrack.app"
    #   http {
    #     path {
    #       path = "/account/*"
    #       backend {
    #         service {
    #           name = "carbontrack-account-api"
    #           port {
    #             number = 3000
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    # rule {
    #   host = "new-dev-api.carbontrack.app"
    #   http {
    #     path {
    #       path = "/track/*"
    #       backend {
    #         service {
    #           name = "carbontrack-track-api"
    #           port {
    #             number = 3000
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    # rule {
    #   host = "new-admin-dev.carbontrack.app"
    #   http {
    #     path {
    #       path = "/*"
    #       backend {
    #         service {
    #           name = "carbontrack-admin-fe-renewal"
    #           port {
    #             number = 3000
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
  }
  depends_on = [
    kubernetes_service.carbon_re_service,
    kubernetes_manifest.carbon_re_gke_cert,
  ]
}

# # 사설 Ingress 리소스 생성
# resource "kubernetes_ingress_v1" "carbon_re_gke_ingress_internal" {
#   wait_for_load_balancer = true
#   # depends_on = [ module.project_namespace ]
#   metadata {
#     name = "carbon-re-gke-ingress-internal"
#     namespace = var.project
#     annotations = {
#       "kubernetes.io/ingress.class" = "gce-internal" # 내부 로드 밸런서 사용
#     }
#   }
#   spec {
#     # ingress_class_name = "gce-internal" # 내부 로드 밸런서 사용
#     default_backend {
#       service {
#         name = "carbon-re-internal-service" # 내부 서비스 사용
#         port {
#           number = 80
#           # name = "http-internal"
#         }
#       }
#     }
    # rule {
    #   host = "dev-rollout.carbontrack.app"
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
    #   host = "dev-mq.carbontrack.app"
    #   http {
    #     path {
    #       path    = "/*"
    #       backend {
    #         service {
    #           name = "carbontrack-rabbitmq-prom"
    #           port {
    #             number = 15692
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
#   }
#   depends_on = [kubernetes_service.carbon_re_internal_service]
# }

# 이미 생성된 글로벌 주소를 참조
data "google_compute_global_address" "ingress_static_ip" {
  name   = "${var.project}-${var.env}-static-ip"
  # region = var.region
}

# 다음 리소스 생성 부분은 이미 존재하므로 주석 처리
# resource "google_compute_global_address" "ingress_static_ip" {
#   name   = "${var.project}-${var.env}-static-ip"
#   # region = var.region
# }

