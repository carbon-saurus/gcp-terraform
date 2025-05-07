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
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.0, < 3.36.0"
      # version = ">= 3.36.0"
    }
  }

  backend "gcs" {
    bucket = "carbonsaurus-re100-dev-devops-bucket"  
    prefix = "terraform/dev/gcp/re100_dev.tfstate"
  }

#   provider_meta "google-beta" {
#     module_name = "blueprints/terraform/terraform-google-kubernetes-engine:beta-autopilot-private-cluster/v22.0.0"
#   }
}

provider "google" {
  credentials = file(var.credentials_path)
  project = var.project_id
  region  = var.region
}


data "google_client_config" "default" {}

# GKE 클러스터 정보 가져오기
# data "google_container_cluster" "my_cluster" {
#   name     = "${local.cluster_name}"
#   location = var.zone
#   project  = var.project_id
# }


provider "kubernetes" {

  # host  = "https://${module.gke.cluster_endpoint}"
  host  = "https://${module.gke.google_container_cluster.primary.endpoint}"
  # host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = module.gke.cluster_ca_certificate

  # host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  # token = data.google_client_config.default.access_token
  # cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gcloud"
    args = [
      "container",
      "clusters",
      "get-credentials",
      local.cluster_name, 
      "--region",
      var.region,
      "--project",
      var.project_id
    ]
  }
}

provider "helm" {
  kubernetes {
    host  = "https://${module.gke.cluster_endpoint}"
    # host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = module.gke.cluster_ca_certificate

    # host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
    # token = data.google_client_config.default.access_token
    # cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gcloud"
    args = [
      "container",
      "clusters",
      "get-credentials",
      local.cluster_name, 
      "--region",
      var.region,
      "--project",
      var.project_id
    ]
  }
  }

}