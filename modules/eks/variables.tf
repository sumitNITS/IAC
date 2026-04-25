variable "environment" {
  description = "Environment name for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "endpoint_sg_id" {
  description = "VPC endpoint security group ID for node egress"
  type        = string
}

variable "support_vpc_cidr" {
  description = "CIDR block of the support VPC for API access restriction"
  type        = string
}

variable "cluster_vpc_cidr" {
  description = "CIDR block of the cluster VPC for API access restriction"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention for EKS cluster logs"
  type        = number
}

variable "node_max_unavailable_percentage" {
  description = "Max unavailable nodes during node group update"
  type        = number
}
