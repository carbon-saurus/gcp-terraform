##############
### secret ###
##############
# resource "google_service_account_key" "external_es_key" {
#   service_account_id = google_service_account.external_es.name
#   private_key_type   = "TYPE_UNSPECIFIED"
# }

# resource "local_file" "sa_key_file" {
#   filename        = "sa_key.json"
#   content         = base64decode(google_service_account_key.external_es_key.private_key)
# }

resource "kubernetes_secret" "gcpsm_k8s_secret" {
  metadata {
    name      = "gcpsm-k8s-secret"
    namespace = var.project
  }
  type = "Opaque"
  data = {
    "gcpsm-k8s-secret.json" = file("external-secret-sa-key.json")
    # "gcpsm-k8s-secret.json" = base64decode(module.iam_config.external_es_key_private_key_data)
  }
  depends_on = [ module.project_namespace ]

}

# resource "google_service_account_key" "gcr_pull_key" {
#   service_account_id = google_service_account.gcr_pull.name
# }

module "dev_gcr_registry" {
  source      = "../../modules/gcr_secret"
  name        = var.secret_name
  namespace   = var.project
  gcr_server  = var.gcr_server
  username    = var.username
  email       = var.email
  # password    = base64decode(module.iam_config.gcr_sa_key_private_key_data)
  password    = file("gcr-sa-key.json")

  depends_on = [ module.project_namespace ]
}

module "asia_gcr_registry" {
  source      = "../../modules/gcr_secret"
  name        = "${var.region}-${var.secret_name}"
  namespace   = var.project
  gcr_server  = var.asia_gcr_server
  username    = var.username
  email       = var.email
  password    = file("gcr-sa-key.json")
  # password    = base64decode(module.iam_config.gcr_sa_key_private_key_data)

  depends_on = [ module.project_namespace ]
}
