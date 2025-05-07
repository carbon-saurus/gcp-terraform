module "istio_system" {
  source = "../../modules/namespace"
  name = "istio-system"
}
module "project_namespace" {
  source = "../../modules/namespace"
  name = var.project
}