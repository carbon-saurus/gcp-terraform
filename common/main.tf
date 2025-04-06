# Enable necessary APIs
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# resource "google_project_service" "storage" {
#   project = var.project_id
#   service = "storage.googleapis.com"
#   disable_on_destroy = false
#   # disable_dependent_services = true 

# }

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

## GKE 서비스 계정 생성
resource "google_service_account" "gke_service_account" {
  account_id   = var.gke_service_account_name
  display_name = "GKE Node Service Account"
}

## GKE 서비스 계정에 필요한 추가 IAM 역할
resource "google_project_iam_member" "gke_sa_monitoring_viewer" {
  project = var.project_id
  role   = "roles/monitoring.viewer"
  member = "serviceAccount:${google_service_account.gke_service_account.email}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_iam_member" "gke_sa_logging_log_writer" {
  project = var.project_id
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Artifact Registry Service Account 생성
resource "google_service_account" "gcr_pull" {
  account_id   = "gcr-sa"
  display_name = "Service Account for pulling images from GCR"

  lifecycle {
    prevent_destroy = true
  }
}

# Artifact Registry Service Account 키 생성
resource "google_service_account_key" "gcr_pull_key" {
  service_account_id = google_service_account.gcr_pull.name
}

# 이미지 Pull 권한 추가
resource "google_project_iam_member" "gcr_pull_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.gcr_pull.email}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_iam_member" "gcr_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gcr_pull.email}"

  lifecycle {
    prevent_destroy = true
  }
}

# Cloud SQL용 Service Account
resource "google_service_account" "cloud_sql_proxy" {
  project      = var.project_id
  account_id   = "cloud-sql-proxy-sa"
  display_name = "Cloud SQL Proxy Service Account"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_iam_binding" "cloud_sql_proxy" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  members  = [
    "serviceAccount:${google_service_account.cloud_sql_proxy.email}"
  ]

  lifecycle {
    prevent_destroy = true
  }
}

# 서비스 계정 키 생성
resource "google_service_account_key" "cloud_sql_proxy" {
  service_account_id = google_service_account.cloud_sql_proxy.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "external_es" {
  account_id   = "external-secrets-sa"
  display_name = "External Secrets Service Account"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_iam_binding" "secret_manager_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${google_service_account.external_es.email}",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

# ExternalSecret 서비스 계정 키 생성
resource "google_service_account_key" "external_es_key" {
  service_account_id = google_service_account.external_es.name
  private_key_type   = "TYPE_UNSPECIFIED"

  lifecycle {
    prevent_destroy = true
  }
}