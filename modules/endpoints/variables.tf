variable "vpc_id" {
  description = "VPC ID where VPC endpoints will be created"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for interface endpoints"
  type        = list(string)
}

variable "private_route_tables" {
  description = "List of private route table IDs for S3 gateway endpoint"
  type        = list(string)
}

variable "region" {
  description = "AWS region for VPC endpoints"
  type        = string
}

variable "cluster_vpc_cidr" {
  description = "CIDR block of the cluster VPC for endpoint access"
  type        = string
}
