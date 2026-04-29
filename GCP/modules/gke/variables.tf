variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the GKE cluster"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC for the GKE cluster"
  type        = string
}

variable "private_subnet_name" {
  description = "Name of the private subnet for GKE nodes"
  type        = string
}

variable "jump_host_subnet_cidr" {
  description = "CIDR block of the jump host subnet allowed to reach the private GKE control plane"
  type        = string
}

variable "pod_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
}

variable "service_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master endpoint (must be a /28)"
  type        = string
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes (equivalent to AWS t3.medium)"
  type        = string
}

variable "node_disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
}

variable "node_disk_type" {
  description = "Disk type for GKE nodes"
  type        = string
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "node_locations" {
  description = "Explicit list of zones for the node pool. Must be zones within the region."
  type        = list(string)
}

variable "pod_range_cidr" {
  description = "CIDR of the secondary IP range used for pods (needed for DNS firewall rule)"
  type        = string
}

variable "deletion_protection" {
  description = "Enable deletion protection for the GKE cluster"
  type        = bool
}
