variable "environment" {
  description = "Environment name for resource naming"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP zone for the jump host VM"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC where the jump host will be launched"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the jump host"
  type        = string
}

variable "cluster_vpc_cidr" {
  description = "CIDR block of cluster VPC (for RDS/Cloud SQL access)"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the jump host (equivalent to t3.micro)"
  type        = string
}

variable "image" {
  description = "Boot image for the jump host VM"
  type        = string
}

variable "kms_key_id" {
  description = "Optional KMS key ID for boot disk encryption"
  type        = string
}

variable "gcs_artifacts_bucket" {
  description = "Optional GCS bucket name for offline artifacts accessible from jump host"
  type        = string
}

variable "deletion_protection" {
  description = "Enable deletion protection for the jump host VM"
  type        = bool
}

variable "admin_email" {
  description = "Email of the admin user who will access the jump host via IAP/OS Login"
  type        = string
}

variable "enable_os_login_project_binding" {
  description = "Enable OS Login IAM binding for the admin user at the project level"
  type        = bool
}
