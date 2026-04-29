variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
}

variable "cluster_vpc_cidr" {
  description = "CIDR block for the GKE cluster VPC"
  type        = string
}

variable "jump_host_subnet_cidr" {
  description = "CIDR block for the jump host subnet"
  type        = string
}

variable "pod_range_cidr" {
  description = "Secondary CIDR for GKE pods (must not overlap with cluster_vpc_cidr)"
  type        = string
}

variable "service_range_cidr" {
  description = "Secondary CIDR for GKE services (must not overlap with cluster_vpc_cidr or pod_range_cidr)"
  type        = string
}
