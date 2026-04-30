output "cluster_name" {
  description = "EKS cluster name"
  value       = module.cluster.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.cluster.cluster_endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.cluster.cluster_arn
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster control plane (module-created)"
  value       = module.cluster.cluster_security_group_id
}

output "node_security_group" {
  description = "Security group ID for EKS nodes"
  value       = module.cluster.node_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA"
  value       = module.cluster.oidc_provider_arn
}

output "oidc_issuer_url" {
  description = "Issuer URL of the EKS OIDC provider"
  value       = module.cluster.oidc_provider
}
