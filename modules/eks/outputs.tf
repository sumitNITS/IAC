output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster control plane"
  value       = aws_security_group.cluster.id
}

output "node_security_group" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.node_sg.id
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.node_role.arn
}

output "node_instance_profile_name" {
  description = "Name of the EKS node instance profile"
  value       = aws_iam_instance_profile.node_profile.name
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_issuer_url" {
  description = "Issuer URL of the EKS OIDC provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "addon_versions" {
  description = "Map of EKS managed add-on names to their versions"
  value       = { for k, v in aws_eks_addon.this : k => v.addon_version }
}
