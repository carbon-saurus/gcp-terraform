data "terraform_remote_state" "gcp" {
  backend = "gcs"
  config = {
      bucket          = "carbonsaurus-dev-devops-bucket" 
      prefix          = "terraform/dev/gcp/carbontrack_renewal.tfstate"
  }
}


# resource "google_service_account" "gcr_pull" {
#   account_id   = "gcr-sa"
#   display_name = "Service Account for pulling images from GCR"
#   project      = var.project_id
# }

# resource "google_project_iam_member" "gcr_pull_secret_accessor" {
#   project = var.project_id
#   role    = "roles/secretmanager.secretAccessor"
#   member  = "serviceAccount:${google_service_account.gcr_pull.email}"
# }

# resource "google_project_iam_member" "gcr_artifact_registry_reader" {
#   project = var.project_id
#   role    = "roles/artifactregistry.reader"
#   member  = "serviceAccount:${google_service_account.gcr_pull.email}"
# }

# resource "google_artifact_registry_repository_iam_member" "repository_reader" {
#   project    = var.project_id
#   location   = var.region
#   repository = "carbon-re-dev-scrap-api"
#   role       = "roles/artifactregistry.reader"
#   member     = "serviceAccount:${google_service_account.gcr_pull.email}"
# }

data "terraform_remote_state" "base_iam" {
  backend = "gcs" 
  config = {
    bucket = "carbonsaurus-dev-devops-bucket"  
    prefix = "terraform/common/gcp/carbontrack_renewal.tfstate"
  } 
}

# module "iam_config" {
#   source = "../../modules/iam"

#   project_id = var.project_id

  # gke_node_sa_email = data.terraform_remote_state.base_iam.outputs.gke_service_account
  # gcr_sa_email      = data.terraform_remote_state.base_iam.outputs.gcr_service_account
  # cloud_sql_proxy_sa_email =  data.terraform_remote_state.base_iam.outputs.cloud_sql_proxy_service_account
  # external_secret_sa_email = data.terraform_remote_state.base_iam.outputs.external_secret_service_account

# }

resource "kubernetes_service_account" "gcr_sa" {
  metadata {
    name      = "gcr-sa"
    namespace = var.project

    annotations = {
      "iam.gke.io/gcp-service-account" = "${data.terraform_remote_state.base_iam.outputs.gke_service_account}"
      # "iam.gke.io/gcp-service-account" = "${module.iam_config.gcr_service_account}"
    }
  }
}

resource "kubernetes_role_binding" "gcr_sa_binding" {
  metadata {
    name      = "gcr-sa-binding"
    namespace = var.project
  }

  role_ref {
    kind     = "ClusterRole"
    name     = "cluster-admin"  # 필요한 권한에 따라 변경 가능
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.gcr_sa.metadata[0].name
    namespace = var.project
  }
}


resource "google_artifact_registry_repository" "gcp_artifact_registry" {
  for_each      = local.applications_map

  project       = var.project_id
  location      = var.region
  repository_id = "${var.project}-${var.env}-${each.value}" 
  format        = "DOCKER"

  description = "Artifact Registry repository for ${each.value}"
}


# Cloud SQL Proxy를 위한 역할 바인딩
# resource "google_service_account" "cloud_sql_proxy" {
#   project       = var.project_id
#   account_id   = "cloud-sql-proxy-sa"
#   display_name = "Cloud SQL Proxy Service Account"
# }

# resource "google_project_iam_binding" "cloud_sql_proxy" {
#   project = var.project_id
#   role    = "roles/cloudsql.client"

#   members = [
#     "serviceAccount:${google_service_account.cloud_sql_proxy.email}",
#   ]
# }

# resource "google_service_account_key" "cloud_sql_proxy" {
#   service_account_id = google_service_account.cloud_sql_proxy.name
# }

resource "kubernetes_secret" "cloud_sql_proxy" {
  metadata {
    name = "cloud-sql-proxy-credentials"
    namespace = var.project
  }

  data = {
    "credentials.json" = base64decode(data.terraform_remote_state.base_iam.outputs.cloud_sql_proxy_sa_key_private_key_data)
  }

  depends_on = [ module.project_namespace ]
}

resource "kubernetes_service_account" "cloud_sql_proxy" {
  metadata {
    name = "cloud-sql-proxy"
    namespace = var.project
  }

  depends_on = [ module.project_namespace ]
}

resource "kubernetes_deployment" "carbon_re_webapp" {
  metadata {
    name = "carbon-re-webapp"
    namespace = var.project
    labels = {
      app = "carbon-re-webapp"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "carbon-re-webapp"
      }
    }
    template {
      metadata {
        labels = {
          app = "carbon-re-webapp"
        }
      }
      spec {
        image_pull_secrets {
          name = "${var.region}-${var.secret_name}"
        }
        container {
          name  = "carbon-re-webapp"
          # 실제 이미지가 없을 수 있으므로 테스트용 공개 이미지로 변경
          image = "nginx:latest"  # 테스트용 nginx 이미지
          # image = "gcr.io/${var.project_id}/carbon-re-webapp:latest"


          env {
            name  = "DB_HOST"
            # value = "carbonsaurus-dev:asia-northeast3:carbon-re-dev-db"
            value_from {
              secret_key_ref {
                name = "db-credentials"
                key  = "DB_HOST"
              }
            }
          }
           env {
            name  = "DB_USER"
            # value = var.db_user
            value_from {
              secret_key_ref {
                name = "db-credentials"
                key  = "DB_USERNAME"
              }
            }
          }
          env {
            name  = "DB_PASSWORD"
             value_from {
              secret_key_ref {
                # name = kubernetes_secret.db_credentials.metadata[0].name
                # key  = "password"
                name = "db-credentials"
                key  = "DB_PASSWORD"
              }
            }
          }
          env {
            name  = "DB_NAME"
            value = "carbon-re-test-db"
          }

          port {
            container_port = 8080
          }
        }
        container {
          name  = "cloud-sql-proxy"
          image = "gcr.io/cloudsql-docker/gce-proxy:1.33.2"
          
          command = [
            "/cloud_sql_proxy",
            "-ip_address_types=PRIVATE",
            # "-instances=${var.project_id}:${var.region}:${data.google_sql_database_instance.carbontrack_db.name}=tcp:5432",
            "-instances=${var.project_id}:${var.region}:${var.project}-${var.env}-db=tcp:5432",
            "-credential_file=/secrets/cloudsql/credentials.json"
          ]

          security_context {
            run_as_non_root = true
          }

          volume_mount {
            name       = "cloud-sql-proxy-credentials"
            mount_path = "/secrets/cloudsql"
            read_only  = true
          }
        }
        volume {
          name = "cloud-sql-proxy-credentials"
          secret {
            secret_name = kubernetes_secret.cloud_sql_proxy.metadata[0].name
          }
        }
        service_account_name = kubernetes_service_account.cloud_sql_proxy.metadata[0].name
      }
    }
  }
}

resource "kubernetes_service" "carbon_re_service" {
  metadata {
    name = "carbon-re-service"
    namespace = var.project
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    selector = {
      app = "carbon-re-webapp"
    }
    type = "ClusterIP"
    port {
      port        = 80
      target_port = 8080
    }
  }
}

# resource "kubernetes_deployment" "carbon-re-internal" {
#   metadata {
#     name = "carbon-re-internal"
#     namespace = var.project
#     labels = {
#       app = "internal-service"
#     }
#   }
#   spec {
#     replicas = 1
#     selector {
#       match_labels = {
#         app = "internal-service"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = "internal-service"
#         }
#       }
#       spec {
#         image_pull_secrets {
#           name = var.secret_name
#         }
#         container {
#           name  = "internal-app"
#           # 실제 이미지가 없을 수 있으므로 테스트용 공개 이미지로 변경 
#           image = "nginx:latest"  # 테스트용 nginx 이미지
#           # image = "gcr.io/${var.project_id}/carbon-re-internal-service:latest"
#           port {
#             container_port = 8081
#           }
#         }
#       }
#     }
#   }
# }

resource "kubernetes_service" "carbon_re_internal_service" {
  metadata {
    name = "carbon-re-internal-service"
    namespace = var.project
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    selector = {
      app = "internal-service"
    }
    type = "ClusterIP"
    port {
      name        = "http-internal"
      protocol    = "TCP"
      port        = 80
      target_port = 8081
    }
  }
}


# resource "kubernetes_deployment" "hello_gke" {
#   metadata {
#     name = "hello-gke"
#     namespace = var.project
#     labels = {
#       app = "hello-gke"
#     }
#   }
#   spec {
#     replicas = 2
#     selector {
#       match_labels = {
#         app = "hello-gke"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = "hello-gke"
#         }
#       }
#       spec {
#         image_pull_secrets {
#           name = var.secret_name
#           # name = "gcp-sa-secret"
#         # }
#         }
#         container {
#           image = "gcr.io/${var.project_id}/hello-gke-service:latest"
#           name  = "hello-gke"

#           env {
#             name  = "DB_HOST"
#             value = "127.0.0.1" # Cloud SQL Proxy가 로컬에서 실행되므로 localhost 사용
#           }
#            env {
#             name  = "DB_USER"
#             value = var.db_user
#             # value_from {
#             #   secret_key_ref {
#             #     name = kubernetes_secret.db_credentials.metadata[0].name
#             #     key  = "username"
#             #   }
#             # }
#           }
#           env {
#             name  = "DB_PASSWORD"
#              value_from {
#               secret_key_ref {
#                 # name = kubernetes_secret.db_credentials.metadata[0].name
#                 # key  = "password"
#                 name = "db-credentials"
#                 key  = "DB_PASSWORD"
#               }
#             }
#           }
#           env {
#             name  = "DB_NAME"
#             value = "carbon-re-dev-db"
#           }
#           port {
#             container_port = 8080
#           }

#           # service_account_name = kubernetes_service_account.cloud_sql_proxy.metadata[0].name
#         }
        
#       # Cloud SQL Proxy 사이드카 컨테이너
#         container {
#           name  = "cloud-sql-proxy"
#           image = "gcr.io/cloudsql-docker/gce-proxy:1.33.2"
          
#           command = [
#             "/cloud_sql_proxy",
#             "-ip_address_types=PRIVATE",
#             # "-instances=${var.project_id}:${var.region}:${data.google_sql_database_instance.carbontrack_db.name}=tcp:5432",
#             "-instances=${var.project_id}:${var.region}:${var.project}-${var.env}-db=tcp:5432",
#             "-credential_file=/secrets/cloudsql/credentials.json"
#           ]

#           security_context {
#             run_as_non_root = true
#           }

#           volume_mount {
#             name       = "cloud-sql-proxy-credentials"
#             mount_path = "/secrets/cloudsql"
#             read_only  = true
#           }
#         }

#         container {
#           name  = "carbon-re-gke-internal-app" 
#           image =  "gcr.io/${var.project_id}/hello-gke-service-internal:latest" 
#           port {
#             container_port = 8081
#             protocol = "TCP"
#           }
#           # 필요한 환경 변수, 볼륨 마운트 등 설정 추가
#         }

#         container {
#           name  = "scrap-api" 
#           image =  "${var.region}-docker.pkg.dev/${var.project_id}/${var.project}-${var.env}-scrap-api/carbon-scrap-api:519c3167d2df5d98ecc426c03fb48cdd1b662c2a" 
#           # asia-northeast3-docker.pkg.dev/carbonsaurus-dev/carbon-re-dev-scrap-api/carbon-scrap-api
#           port {
#             container_port = 8082
#             protocol = "TCP"
#           }
#           # 필요한 환경 변수, 볼륨 마운트 등 설정 추가
#         }

#         volume {
#           name = "cloud-sql-proxy-credentials"
#           secret {
#             secret_name = kubernetes_secret.cloud_sql_proxy.metadata[0].name
#           }
#         }

#         service_account_name = kubernetes_service_account.cloud_sql_proxy.metadata[0].name
#       }
#     }
#   }

#   depends_on = [
#     kubernetes_secret.cloud_sql_proxy,
#     kubernetes_service_account.cloud_sql_proxy
#   ]
# }
# # 서비스 생성 (LoadBalancer 타입으로 변경)
# resource "kubernetes_service" "carbon_re_service" {
#   metadata {
#     name = "carbon-re-service"
#     namespace = var.project
#     annotations = {
#       "cloud.google.com/neg" = "{\"ingress\": true}"  # 네트워크 엔드포인트 그룹 활성화
#     }
#   }
#   spec {
#     selector = {
#       app = kubernetes_deployment.hello_gke.metadata[0].labels.app
#     }

#     type = "NodePort"

#     port {
#       port        = 80
#       target_port = 8080
#     }
#   }
# }

# resource "kubernetes_service" "carbon_re_gke_service_internal" {
#   metadata {
#     name = "carbon-re-internal-service"
#     namespace = var.project
#     annotations = {
#       "cloud.google.com/neg" = "{\"ingress\": true}" 
#     }
#   }
#   spec {
#     selector = {
#       app = kubernetes_deployment.hello_gke.metadata[0].labels.app
#     }

#     type = "ClusterIP" # 내부 서비스는 ClusterIP 타입 사용

#     port {
#       name        = "http-internal"
#       protocol    = "TCP"
#       port        = 80
#       target_port = 8081
#     }
#   }
# }

# resource "kubernetes_service" "carbon_re_dev_scrap_api" {
#   metadata {
#     name = "carbon-re-dev-scrap-api"
#     namespace = var.project
#     annotations = {
#       "cloud.google.com/neg" = "{\"ingress\": true}" 
#     }
#   }
#   spec {
#     selector = {
#       app = kubernetes_deployment.hello_gke.metadata[0].labels.app
#     }

#     type = "ClusterIP" # 내부 서비스는 ClusterIP 타입 사용

#     port {
#       # name        = "http-internal"
#       protocol    = "TCP"
#       port        = 80
#       target_port = 8082
#     }
#   }
# }