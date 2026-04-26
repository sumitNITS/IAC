variable "environment" {
  description = "Environment name for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region for prefix list lookups"
  type        = string
  default     = "ap-south-1"
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

variable "support_vpc_cidr" {
  description = "CIDR block of the support VPC"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the SSM jump host"
  type        = string
}

variable "ami_name_pattern" {
  description = "AMI name pattern for the SSM jump host"
  type        = string
}

variable "s3_artifacts_bucket" {
  description = "Optional S3 bucket name for offline artifacts accessible from jump host"
  type        = string
  default     = null
}

variable "s3_artifacts_prefix" {
  description = "Optional S3 prefix (without leading slash) for offline artifacts"
  type        = string
  default     = null
}
