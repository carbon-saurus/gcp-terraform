data "kubernetes_namespace" "all" {
  metadata {
    name = var.name
  }
}

resource "kubernetes_namespace" "this" {
  count = data.kubernetes_namespace.all.metadata.0.name == var.name ? 0 : 1
  metadata {
    name = var.name
    labels = {
        shared-gateway-access: "true"
        "kubernetes.io/metadata.name": var.name
    }
  }
}
