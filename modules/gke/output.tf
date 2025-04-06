output "cluster_id" {
  value = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}
output "cluster_public_endpoint" {
  value = google_container_cluster.primary.private_cluster_config[0].public_endpoint
}

output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

output "node_pool" {
  value = google_container_node_pool.cluster-nodes
}

output "node_pool_ready" {
  value = null_resource.node_pool_ready
}