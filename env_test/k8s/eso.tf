locals {
  applications_map = { for idx, app in var.applications : app => app }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  version          = "v0.14.4"
  create_namespace = true
  values = [
    yamlencode({
      webhook = {
        port = 9443
      },
    })
  ]
}

###########
### GSM ###
###########

resource "google_secret_manager_secret" "project_gsm" {
  for_each = local.applications_map
  secret_id = "${var.project}-${var.env}-${each.key}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
    # auto {}
  }

}

resource "google_secret_manager_secret_version" "project_gsm_version" {
  for_each = local.applications_map
  secret   = google_secret_manager_secret.project_gsm[each.key].id
  secret_data_wo = each.value
}

################
### manifest ###
################

resource "kubectl_manifest" "secret_store" {
  # yaml_body = templatefile("${path.module}/manifest/secret-store.yaml", {
  yaml_body = templatefile("${path.module}/manifest/secret-store.yaml", {
    namespace = var.project
    project_id = var.project_id
    cluster_location = var.region
    cluster_name     = "${var.project}-${var.env}-cluster"
    ksa_name          = var.ksa_name
    # ksa_namespace     = kubernetes_service_account.external_es.metadata[0].namespace
  })
  depends_on = [module.project_namespace, helm_release.external_secrets]
}


resource "kubectl_manifest" "gcpsm_secret" {
  for_each = google_secret_manager_secret.project_gsm
  yaml_body = templatefile("${path.module}/manifest/external-secret.yaml", {
    name      = each.key
    namespace = var.project
    interval  = "10s"
    # secret_id = each.value.secret_id
    gsm_path = "${var.project}-${var.env}-${each.key}"
  })
  depends_on = [module.project_namespace, helm_release.external_secrets]
}

# resource "local_file" "rendered_yaml" {
#   for_each = google_secret_manager_secret.project_gsm
#   content  = templatefile("${path.module}/manifest/external-secret.yaml", {
#     name      = each.key
#     namespace = var.project
#     interval  = "10s"
#     gsm_path = "${var.project}-${var.env}-${each.key}"
#   })
#   filename = "${path.module}/rendered-external-secret-${each.key}.yaml"
# }

##########
### sa ###
##########

# IAM 역할 바인딩 생성 (Secret Manager 접근 권한)
# resource "google_project_iam_binding" "secret_manager_access" {
#   project = var.project_id
#   role    = "roles/secretmanager.secretAccessor"
#   members = [
#     "serviceAccount:${module.iam_config.external_es_service_account}",
#   ]
# }

// Kubernetes 서비스 계정 생성
resource "kubernetes_service_account" "external_es" {
  metadata {
    name      = "external-secrets-sa"
    namespace = "external-secrets" 
    annotations = {
      "iam.gke.io/gcp-service-account" = data.terraform_remote_state.base_iam.outputs.external_secret_service_account
      # "iam.gke.io/gcp-service-account" = module.iam_config.external_es_service_account
    }
  }
  depends_on = [ helm_release.external_secrets ]
}

# IAM 역할 바인딩 생성 (Workload Identity 사용자 권한)
# resource "google_service_account_iam_binding" "workload_identity_user" {
#   service_account_id = google_service_account.external_es.name
#   role               = "roles/iam.workloadIdentityUser"
#   members = [
#     "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_service_account.external_es.metadata[0].namespace}/${kubernetes_service_account.external_es.metadata[0].name}]",
#   ]

#   depends_on = [ module.project_namespace ]
# }