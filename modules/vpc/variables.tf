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
  description = "List of availability zones"
  type        = list(string)
}

variable "subnet_multiplier" {
  description = "Multiplier for subnet counts per AZ"
  type        = number
}
