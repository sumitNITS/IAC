variable "environment" {
  description = "Environment name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the SSM EC2 instance will be launched"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EC2 instance placement"
  type        = list(string)
}

variable "cluster_vpc_cidr" {
  description = "CIDR block of cluster VPC (for RDS access)"
  type        = string
}

variable "eks_node_sg" {
  description = "EKS node security group ID"
  type        = string
}
