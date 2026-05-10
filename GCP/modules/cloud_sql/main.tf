terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

# KMS for Cloud SQL Encryption
resource "random_id" "kms_suffix" {
  byte_length = 4
}

resource "google_kms_key_ring" "cloud_sql" {
  name     = "${var.environment}-cloud-sql-keyring-${random_id.kms_suffix.hex}"
  location = var.region
}

resource "google_kms_crypto_key" "cloud_sql" {
  name            = "${var.environment}-cloud-sql-key-${random_id.kms_suffix.hex}"
  key_ring        = google_kms_key_ring.cloud_sql.id
  rotation_period = "7776000s" # 90 days

  purpose = "ENCRYPT_DECRYPT"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Retrieve the Cloud SQL service identity (robot account) so we don't need project_number
resource "google_project_service_identity" "cloud_sql" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"
}

# Allow Cloud SQL service account to use the KMS key
resource "google_kms_crypto_key_iam_member" "cloud_sql_encrypt_decrypt" {
  crypto_key_id = google_kms_crypto_key.cloud_sql.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.cloud_sql.email}"
}

# Private Service Access (for private IP Cloud SQL)
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "${var.environment}-cloud-sql-private-ip"
  purpose       = "VPC_PEERING"
  address       = var.private_service_access_address
  address_type  = "INTERNAL"
  network       = var.vpc_id
  prefix_length = var.private_service_access_prefix_length
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# Secret Manager for DB Credentials
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.environment}-db-password"

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "random_password" "db_password" {
  length      = 24
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Cloud SQL Instance
resource "google_sql_database_instance" "primary" {
  name             = "${var.environment}-postgres"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
    }

    backup_configuration {
      enabled    = var.backup_enabled
      start_time = var.backup_start_time

      backup_retention_settings {
        retained_backups = var.backup_retention_count
      }
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    disk_autoresize = var.disk_autoresize
    disk_size       = var.disk_size
    disk_type       = var.disk_type

    availability_type = var.availability_type # REGIONAL = Multi-AZ equivalent

    maintenance_window {
      day          = 7 # Sunday
      hour         = 3
      update_track = "stable"
    }

    user_labels = {
      environment = var.environment
      managed_by  = "terraform"
    }
  }

  encryption_key_name = google_kms_crypto_key.cloud_sql.id

  deletion_protection = var.deletion_protection

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_kms_crypto_key_iam_member.cloud_sql_encrypt_decrypt,
  ]
}

resource "google_sql_database" "app" {
  name     = var.db_name
  instance = google_sql_database_instance.primary.name
}

resource "google_sql_user" "admin" {
  name     = var.db_username
  instance = google_sql_database_instance.primary.name
  password = random_password.db_password.result
}
