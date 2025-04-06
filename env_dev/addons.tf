# GKE 클러스터의 인증 정보를 가져오는 null_resource
resource "null_resource" "get_gke_credentials" {
  depends_on = [ module.gke ]

  provisioner "local-exec" {
     command = "gcloud container clusters get-credentials ${var.project}-${var.env}-cluster --region ${var.region} --project ${var.project_id}"
  
  }
}

# Argo Rollouts Helm 차트를 설치하는 helm_release 리소스
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

# Stakater Reloader Helm 차트를 설치하는 helm_release 리소스
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
