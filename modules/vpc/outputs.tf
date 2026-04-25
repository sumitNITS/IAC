output "cluster_vpc_id" {
  description = "The ID of the EKS cluster VPC (10.10.0.0/16)"
  value       = aws_vpc.cluster.id
}

output "cluster_public_subnets" {
  description = "List of public subnet IDs in the cluster VPC (for ALB/NAT Gateway)"
  value       = aws_subnet.public[*].id
}

output "cluster_private_subnets" {
  description = "List of private subnet IDs in the cluster VPC (for EKS nodes)"
  value       = aws_subnet.private[*].id
}

output "cluster_db_subnets" {
  description = "List of DB subnet IDs in the cluster VPC (for RDS)"
  value       = aws_subnet.db[*].id
}

output "cluster_private_route_tables" {
  description = "List of private route table IDs in the cluster VPC for NAT routing"
  value       = aws_route_table.private[*].id
}

output "support_vpc_id" {
  description = "The ID of the support VPC (10.20.0.0/16) for SSM jump host"
  value       = aws_vpc.support.id
}

output "support_private_subnets" {
  description = "List of private subnet IDs in the support VPC (for EC2 SSM jump host)"
  value       = aws_subnet.support_private[*].id
}

output "support_private_route_tables" {
  description = "List of private route table IDs in the support VPC for peering routes"
  value       = aws_route_table.support_private[*].id
}

output "vpc_id" {
  description = "Cluster VPC ID"
  value       = aws_vpc.cluster.id
}

output "private_subnets" {
  description = "List of private subnet IDs in the cluster VPC"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "List of public subnet IDs in the cluster VPC"
  value       = aws_subnet.public[*].id
}

output "private_route_tables" {
  description = "List of private route table IDs in the cluster VPC"
  value       = aws_route_table.private[*].id
}