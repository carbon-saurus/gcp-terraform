output "network_id" {
  value = google_compute_network.carbon_network.self_link
}

output "network_name" {
  value = google_compute_network.carbon_network.name
}

output "network_self_link" {
  value = google_compute_network.carbon_network.self_link
}

output "public_subnet_id" {
  value = google_compute_subnetwork.public_subnet.id
}

output "private_subnet_id" {
  value = google_compute_subnetwork.private_subnet.id
}

output "intra_subnet_id" {
  value = google_compute_subnetwork.database_subnet.id
}

output "private_subnet_cidr" {
  value = google_compute_subnetwork.private_subnet.ip_cidr_range
}
output "public_subnet_cidr" {
  value = google_compute_subnetwork.public_subnet.ip_cidr_range
}