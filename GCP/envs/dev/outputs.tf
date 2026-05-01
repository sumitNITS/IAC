# VPC Outputs
output "cluster_vpc_id" {
  description = "ID of the GKE cluster VPC"
  value       = module.vpc.cluster_vpc_id
}

output "cluster_vpc_name" {
  description = "Name of the GKE cluster VPC"
  value       = module.vpc.cluster_vpc_name
}

output "cluster_private_subnet_id" {
  description = "ID of the private subnet in cluster VPC"
  value       = module.vpc.cluster_private_subnet_id
}

output "jump_host_subnet_id" {
  description = "The ID of the isolated subnet for the jump host"
  value       = module.vpc.jump_host_subnet_id
}

# Jump Host Outputs
output "jump_host_instance_id" {
  description = "Compute Engine instance ID for IAP jump host access"
  value       = module.compute_jump_host.instance_id
}

output "jump_host_instance_name" {
  description = "Name of the jump host VM"
  value       = module.compute_jump_host.instance_name
}

output "jump_host_service_account_email" {
  description = "Email of the jump host service account"
  value       = module.compute_jump_host.service_account_email
}

# GKE Outputs
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "Private endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
}

output "gke_cluster_id" {
  description = "ID of the GKE cluster"
  value       = module.gke.cluster_id
}

output "gke_node_service_account_email" {
  description = "Email of the GKE node service account"
  value       = module.gke.node_service_account_email
}

output "gke_workload_identity_pool" {
  description = "Workload identity pool for Workload Identity"
  value       = module.gke.workload_identity_pool
}

# Quick Reference Commands
output "kubectl_config_command" {
  description = "Command to get credentials for the GKE cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

output "iap_ssh_command" {
  description = "Command to SSH into the jump host via IAP"
  value       = module.compute_jump_host.iap_ssh_command
}
