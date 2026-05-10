variable "environment" {
  description = "Environment name for resource naming"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud SQL"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Cloud SQL will have a private IP"
  type        = string
}

variable "private_service_access_address" {
  description = "Base address of the dedicated private services access range for Cloud SQL"
  type        = string
}

variable "private_service_access_prefix_length" {
  description = "Prefix length of the dedicated private services access range for Cloud SQL"
  type        = number
}

variable "db_tier" {
  description = "Cloud SQL machine tier (equivalent to db.t3.medium)"
  type        = string
}

variable "db_name" {
  description = "Name of the default database"
  type        = string
}

variable "db_username" {
  description = "Master username for Cloud SQL"
  type        = string
}

variable "disk_size" {
  description = "Initial disk size in GB"
  type        = number
}

variable "disk_type" {
  description = "Disk type for Cloud SQL"
  type        = string
}

variable "disk_autoresize" {
  description = "Enable automatic disk resizing"
  type        = bool
}

variable "availability_type" {
  description = "Availability type: REGIONAL (Multi-AZ) or ZONAL (single zone)"
  type        = string
}

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
}

variable "backup_start_time" {
  description = "UTC time window for backups (HH:MM format)"
  type        = string
}

variable "backup_retention_count" {
  description = "Number of backups to retain"
  type        = number
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}
