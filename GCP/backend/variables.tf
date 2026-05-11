variable "project_id" {
  description = "GCP Project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "GCP region for the state bucket"
  type        = string
}

variable "admin_email" {
  description = "Email address of the admin user who will impersonate the Terraform service account (e.g., yourname@gmail.com)"
  type        = string
}