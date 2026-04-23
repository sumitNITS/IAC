variable "cluster_vpc_id" {
  description = "ID of the cluster VPC"
  type        = string
}

variable "support_vpc_id" {
  description = "ID of the support VPC"
  type        = string
}

variable "cluster_vpc_cidr" {
  description = "CIDR block of the cluster VPC"
  type        = string
}

variable "support_vpc_cidr" {
  description = "CIDR block of the support VPC"
  type        = string
}

variable "cluster_route_table_ids" {
  description = "List of route table IDs in the cluster VPC"
  type        = list(string)
}

variable "support_route_table_ids" {
  description = "List of route table IDs in the support VPC"
  type        = list(string)
}
