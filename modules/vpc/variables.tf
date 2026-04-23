variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "cluster_vpc_cidr" {
  description = "CIDR block for the EKS cluster VPC"
  type        = string
}

variable "support_vpc_cidr" {
  description = "CIDR block for the support VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones in ap-south-1"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}
