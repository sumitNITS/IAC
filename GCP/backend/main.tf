terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# GCS Bucket for Terraform State
resource "google_storage_bucket" "tf_state" {
  name                        = "tf-state-files-${var.project_id}-${var.region}"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  labels = {
    environment = "global"
    managed_by  = "terraform"
    purpose     = "tf-state"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 10
      with_state         = "ARCHIVED"
    }
  }
}

# Terraform Service Account
resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
  description  = "Service account used by Terraform to manage infrastructure and access state"
}

# Bucket IAM: Allow Terraform SA full object access to the state bucket
resource "google_storage_bucket_iam_member" "terraform_sa_object_admin" {
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Bucket IAM: Allow Terraform SA to read bucket metadata (required by backend)
resource "google_storage_bucket_iam_member" "terraform_sa_bucket_reader" {
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Service Account IAM: Allow admin user to impersonate the Terraform SA (required for Terraform CLI operations)
resource "google_service_account_iam_member" "terraform_sa_impersonation" {
  service_account_id = google_service_account.terraform_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${var.admin_email}"
}

# Grant the Terraform SA necessary project-level administrative permissions
resource "google_project_iam_member" "terraform_sa_roles" {
  for_each = toset([
    "roles/editor",                          # Base resource management
    "roles/resourcemanager.projectIamAdmin", # Allow SA to grant IAM roles (fixes "Policy update access denied")
    "roles/cloudkms.admin",                  # Allow SA to manage KMS keys and IAM (fixes KMS 403 errors)
    "roles/compute.networkAdmin",            # Allow SA to manage VPC peering for Cloud SQL
    "roles/secretmanager.admin",             # Allow SA to manage and access DB secrets
    "roles/servicenetworking.admin"          # Allow SA to manage Private Service Access connections (fixes Cloud SQL peering 403)
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}