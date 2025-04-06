resource "kubernetes_secret" "docker_registry_secret" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.gcr_server) = {
          username = var.username
          password = var.password
          email    = var.email
          auth     = base64encode("${var.username}:${var.password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}