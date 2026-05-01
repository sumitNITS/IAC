variable "project_id" {
  description = "GCP Project ID where resources will be created"
  type        = string
  default     = "value"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
  default     = "value"
}

variable "zone" {
  description = "GCP zone for the jump host VM"
  type        = string
  default     = "value"
}

# VPC
variable "cluster_vpc_cidr" {
  description = "CIDR block for the GKE cluster VPC"
  type        = string
  default     = "value"
}

variable "jump_host_subnet_cidr" {
  description = "CIDR block for the jump host's isolated subnet within the cluster VPC"
  type        = string
  default     = "value"
}

variable "pod_range_cidr" {
  description = "Secondary CIDR for GKE pods"
  type        = string
  default     = "value"
}

variable "service_range_cidr" {
  description = "Secondary CIDR for GKE services"
  type        = string
  default     = "value"
}

# GKE
variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master endpoint (/28)"
  type        = string
  default     = "value"
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes (equivalent to AWS t3.medium)"
  type        = string
  default     = "value"
}

variable "node_disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 20 # Reduced to stay within SSD_TOTAL_GB quota (30GB * 3 zones * 3 max nodes = 270GB, exceeds 250GB quota)
}

variable "node_disk_type" {
  description = "Disk type for GKE nodes"
  type        = string
  default     = "value"
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

variable "node_locations" {
  description = "Explicit list of zones for the GKE node pool"
  type        = list(string)
  default     = ["value", "value", "value"]
}

variable "gke_deletion_protection" {
  description = "Enable deletion protection for the GKE cluster"
  type        = bool
  default     = true
}

# Jump Host
variable "jump_host_machine_type" {
  description = "Machine type for the IAP jump host (equivalent to t3.micro)"
  type        = string
  default     = "value"
}

variable "jump_host_image" {
  description = "Boot image for the jump host VM"
  type        = string
  default     = "value"
}

variable "gcs_artifacts_bucket" {
  description = "GCS bucket holding offline tools and packages for the jump host"
  type        = string
  default     = "value"
}

variable "jump_host_deletion_protection" {
  description = "Enable deletion protection for the jump host VM"
  type        = bool
  default     = true
}

variable "admin_email" {
  description = "Email of the admin user who will access the jump host via IAP/OS Login"
  type        = string
  default     = "value"
}

variable "enable_os_login_project_binding" {
  description = "Enable OS Login IAM binding for the admin user"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key ID for boot disk encryption"
  type        = string
  default     = null
}