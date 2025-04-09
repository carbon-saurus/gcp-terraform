terraform {
  required_version = ">= 1.11.1"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.24.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = ">= 2.17.0"
    # }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = ">= 2.36.0"
    # }
  }

  backend "gcs" {
    bucket = "carbonsaurus-dev-devops-bucket"  # GCP에서 원격 상태 저장용 GCS 버킷 이름 (예: "my-gcp-terraform-state")
    prefix = "terraform/prod/k8s/carbontrack-renewal.tfstate"
  }
}

provider "google" {
  credentials = file(var.credentials_path)
  project = var.project_id
  region  = var.region
}


data "google_client_config" "default" {}

# GKE 클러스터 정보 가져오기
data "google_container_cluster" "my_cluster" {
  name     = "${var.project}-${var.env}-cluster"
  # location = var.zone
  location = var.region
  project  = var.project_id
}

provider "kubectl" {
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)
  load_config_file       = false
}

provider "kubernetes" {
  # host  = module.gke.cluster_endpoint
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)
  # cluster_ca_certificate = base64decode(
  #   module.gke.cluster_ca_certificate
  # )
}

provider "helm" {
  kubernetes {
     host  = "${data.google_container_cluster.my_cluster.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)

  }
}