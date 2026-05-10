variable "project_id" {
  description = "GCP Project ID where resources will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
}

variable "zone" {
  description = "GCP zone for the jump host VM"
  type        = string
}

# VPC
variable "cluster_vpc_cidr" {
  description = "CIDR block for the GKE cluster VPC"
  type        = string
}

variable "jump_host_subnet_cidr" {
  description = "CIDR block for the jump host's isolated subnet within the cluster VPC"
  type        = string
}

variable "pod_range_cidr" {
  description = "Secondary CIDR for GKE pods"
  type        = string
}

variable "service_range_cidr" {
  description = "Secondary CIDR for GKE services"
  type        = string
}

# GKE
variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master endpoint (/28)"
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
  description = "Explicit list of zones for the GKE node pool"
  type        = list(string)
}

variable "gke_deletion_protection" {
  description = "Enable deletion protection for the GKE cluster"
  type        = bool
}

variable "enable_cilium_clusterwide_network_policy" {
  description = "Enable Cilium ClusterWide Network Policy on GKE (requires Dataplane V2). Allows defining network policies that apply across all namespaces."
  type        = bool
}

# Jump Host
variable "jump_host_machine_type" {
  description = "Machine type for the IAP jump host (equivalent to t3.micro)"
  type        = string
}

variable "jump_host_image" {
  description = "Boot image for the jump host VM"
  type        = string
}

variable "gcs_artifacts_bucket" {
  description = "GCS bucket holding offline tools and packages for the jump host"
  type        = string
}

variable "jump_host_deletion_protection" {
  description = "Enable deletion protection for the jump host VM"
  type        = bool
}

variable "admin_email" {
  description = "Email of the admin user who will access the jump host via IAP/OS Login"
  type        = string
}

variable "enable_os_login_project_binding" {
  description = "Enable OS Login IAM binding for the admin user"
  type        = bool
}

variable "kms_key_id" {
  description = "Optional KMS key ID for boot disk encryption"
  type        = string
}

# Jump Host Outbound Internet Access
variable "enable_jump_host_nat" {
  description = "Enable Cloud NAT for the jump host subnet to allow outbound internet access"
  type        = bool
}

variable "enable_restricted_jump_host_egress" {
  description = "Restrict jump host outbound traffic to HTTPS (443) and DNS (53) only"
  type        = bool
}

# Cloud SQL
variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
}

variable "db_name" {
  description = "Name of the application database"
  type        = string
}

variable "db_username" {
  description = "Admin username for Cloud SQL"
  type        = string
}

variable "db_disk_size" {
  description = "Initial disk size for Cloud SQL in GB"
  type        = number
}

variable "db_disk_type" {
  description = "Disk type for Cloud SQL"
  type        = string
}

variable "db_disk_autoresize" {
  description = "Enable Cloud SQL disk autoresize"
  type        = bool
}

variable "db_availability_type" {
  description = "Cloud SQL availability type"
  type        = string
}

variable "db_backup_enabled" {
  description = "Enable automated backups for Cloud SQL"
  type        = bool
}

variable "db_backup_start_time" {
  description = "UTC backup start time for Cloud SQL"
  type        = string
}

variable "db_backup_retention_count" {
  description = "Number of Cloud SQL backups to retain"
  type        = number
}

variable "cloud_sql_deletion_protection" {
  description = "Enable deletion protection for Cloud SQL"
  type        = bool
}

variable "create_database" {
  description = "Whether to create the Cloud SQL database module. Set to false to safely delete the database after the full environment is created."
  type        = bool
}

variable "private_service_access_address" {
  description = "Base address of the dedicated private services access range for Cloud SQL"
  type        = string
}

variable "private_service_access_prefix_length" {
  description = "Prefix length of the dedicated private services access range for Cloud SQL"
  type        = number
}