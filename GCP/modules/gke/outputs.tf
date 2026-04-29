output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Private endpoint of the GKE cluster"
  value       = google_container_cluster.primary.private_cluster_config[0].private_endpoint
}

output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "node_service_account_email" {
  description = "Email of the GKE node service account"
  value       = google_service_account.gke_nodes.email
}

output "workload_identity_pool" {
  description = "Workload identity pool for Workload Identity"
  value       = "${var.project_id}.svc.id.goog"
}