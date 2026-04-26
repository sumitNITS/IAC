variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "value"
}

variable "cluster_vpc_cidr" {
  description = "CIDR block for the EKS cluster VPC"
  type        = string
  default     = "value"
}

variable "support_vpc_cidr" {
  description = "CIDR block for the support VPC"
  type        = string
  default     = "value"
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "value"
    ManagedBy   = "Terraform"
  }
}

# VPC
variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["value", "value", "value"]
}

variable "subnet_multiplier" {
  description = "Multiplier for subnet counts per AZ (1 for dev/stage, 2 for prod)"
  type        = number
  default     = 1
}

# EKS
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "value"
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
  default     = ["value"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention for EKS cluster logs"
  type        = number
  default     = 365
}

variable "node_max_unavailable_percentage" {
  description = "Max unavailable nodes during node group update"
  type        = number
  default     = 25
}

# EC2 SSM
variable "ssm_instance_type" {
  description = "Instance type for the SSM jump host"
  type        = string
  default     = "value"
}

variable "ssm_ami_name_pattern" {
  description = "AMI name pattern for the SSM jump host"
  type        = string
  default     = "value"
}

variable "ssm_artifacts_bucket" {
  description = "Optional S3 bucket for offline artifacts consumed by jump host"
  type        = string
  default     = "value"
}

variable "ssm_artifacts_prefix" {
  description = "Optional S3 prefix for offline artifacts consumed by jump host"
  type        = string
  default     = "value"
}