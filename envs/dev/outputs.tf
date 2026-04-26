# VPC Outputs
output "cluster_vpc_id" {
  description = "ID of the EKS cluster VPC"
  value       = module.vpc.cluster_vpc_id
}

output "cluster_private_subnets" {
  description = "IDs of private subnets in cluster VPC"
  value       = module.vpc.cluster_private_subnets
}

output "cluster_public_subnets" {
  description = "IDs of public subnets in cluster VPC"
  value       = module.vpc.cluster_public_subnets
}

output "cluster_db_subnets" {
  description = "IDs of database subnets in cluster VPC"
  value       = module.vpc.cluster_db_subnets
}

output "support_vpc_id" {
  description = "ID of the support VPC"
  value       = module.vpc.support_vpc_id
}

output "support_private_subnets" {
  description = "IDs of private subnets in support VPC"
  value       = module.vpc.support_private_subnets
}

# VPC Peering Outputs
output "peering_connection_id" {
  description = "ID of the VPC peering connection between cluster and support VPCs"
  value       = module.vpc_peering.peering_connection_id
}

output "peering_connection_status" {
  description = "Status of the VPC peering connection"
  value       = module.vpc_peering.peering_connection_status
}

# EC2 SSM Outputs
output "ssm_instance_id" {
  description = "EC2 instance ID for SSM session manager access"
  value       = module.ec2_ssm.instance_id
}

output "ssm_instance_arn" {
  description = "ARN of the SSM EC2 instance"
  value       = module.ec2_ssm.instance_arn
}

output "ssm_security_group_id" {
  description = "Security group ID of the SSM instance"
  value       = module.ec2_ssm.security_group_id
}

# EKS Outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint (private)"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group" {
  description = "Security group ID for EKS nodes"
  value       = module.eks.node_security_group
}

output "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_issuer_url" {
  description = "Issuer URL of the EKS OIDC provider"
  value       = module.eks.oidc_issuer_url
}

# VPC Endpoints Outputs
output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = module.endpoints.s3_endpoint_id
}

output "endpoint_security_group_id" {
  description = "Security group ID used for VPC endpoints"
  value       = module.endpoints.endpoint_security_group_id
}

output "support_endpoint_security_group_id" {
  description = "Security group ID used for support VPC endpoints"
  value       = module.endpoints.support_endpoint_security_group_id
}

output "interface_endpoint_ids" {
  value = module.endpoints.interface_endpoint_ids
}

# Quick Reference for kubectl Configuration
output "kubectl_config_command" {
  description = "Command to update kubeconfig for EKS cluster access"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ssm_session_command" {
  description = "Command to start SSM session to jump host"
  value       = "aws ssm start-session --target ${module.ec2_ssm.instance_id}"
}
