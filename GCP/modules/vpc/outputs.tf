output "cluster_vpc_id" {
  description = "The ID of the GKE cluster VPC"
  value       = google_compute_network.cluster.id
}

output "cluster_vpc_name" {
  description = "The name of the GKE cluster VPC"
  value       = google_compute_network.cluster.name
}

output "cluster_private_subnet_id" {
  description = "ID of the private subnet in the cluster VPC (for GKE nodes)"
  value       = google_compute_subnetwork.private.id
}

output "cluster_private_secondary_range_name" {
  description = "Name of the secondary IP range for GKE pods"
  value       = "pods"
}

output "cluster_services_secondary_range_name" {
  description = "Name of the secondary IP range for GKE services"
  value       = "services"
}

output "jump_host_subnet_id" {
  description = "ID of the isolated subnet for the jump host"
  value       = google_compute_subnetwork.jump_host.id
}
