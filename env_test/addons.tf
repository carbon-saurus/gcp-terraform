resource "null_resource" "get_gke_credentials" {
  depends_on = [ module.gke ]

  provisioner "local-exec" {
     command = "gcloud container clusters get-credentials ${var.project}-${var.env}-cluster --region ${var.region} --project ${var.project_id}"
  #   command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project_id} && echo 'Credentials fetched successfully' > ${path.module}/credentials.txt"
  
  }
}
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  namespace        = var.project
  create_namespace = true
  version          = "2.39.0"

  # Timeout 설정 추가
  timeout = 600
#   wait    = true

  values = [
    yamlencode({
      dashboard = {
          enabled = true
      }
    })
  ]
  depends_on = [ module.gke, null_resource.get_gke_credentials ]
}


resource "helm_release" "stakater-reloader" {
  name             = "stakater"
  repository       = "https://stakater.github.io/stakater-charts"
  chart            = "reloader"
  namespace        = var.project
  create_namespace = true
  version          = "2.0.0"
  depends_on = [ module.gke, null_resource.get_gke_credentials ]

  # Timeout 설정 추가
  timeout = 600
#   wait    = true
}
