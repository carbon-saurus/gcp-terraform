terraform {
  required_version = ">= 1.11.1"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.24.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.0, < 3.36.0"
      # version = ">= 3.36.0"
    }
  }

  backend "gcs" {
    bucket = "carbonsaurus-dev-devops-bucket"  
    prefix = "terraform/common/gcp/carbontrack_renewal.tfstate"
  }

}

provider "google" {
  credentials = file(var.credentials_path)
  project = var.project_id
  region  = var.region
}

