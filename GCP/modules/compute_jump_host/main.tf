terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Jump Host Service Account
resource "google_service_account" "jump_host" {
  account_id   = "${var.environment}-jump-host"
  display_name = "Jump Host Service Account"
  description  = "Service account for the IAP-accessible jump host VM"
}

# Grant jump host admin access to GKE clusters (equivalent to EKS full admin)
resource "google_project_iam_member" "jump_host_container_admin" {
  project = var.project_id
  role    = "roles/container.developer" #roles/container.admin 
  member  = "serviceAccount:${google_service_account.jump_host.email}"
}

# Optional bucket-scoped access for offline tools and artifacts.
resource "google_storage_bucket_iam_member" "jump_host_artifacts_reader" {
  count  = var.gcs_artifacts_bucket != null ? 1 : 0
  bucket = var.gcs_artifacts_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.jump_host.email}"
}

# Jump Host VM
resource "google_compute_instance" "jump_host" {
  name         = "${var.environment}-jump-host"
  machine_type = var.machine_type
  zone         = var.zone

  deletion_protection = var.deletion_protection

  boot_disk {
    initialize_params {
      image = var.image
      size  = 20
      type  = "pd-ssd"
    }

    kms_key_self_link = var.kms_key_id
  }

  network_interface {
    subnetwork = var.subnet_id
    # NO access_config = NO external IP
  }

  metadata = {
    enable-oslogin          = "TRUE"
    enable-guest-attributes = "TRUE"
  }

  service_account {
    email = google_service_account.jump_host.email
    # The jump host uses Private Google Access for GCS and GKE API calls.
    # cloud-platform keeps the VM usable without adding broad project IAM.
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  tags = ["${var.environment}-jump-host"]

  shielded_instance_config {
    enable_secure_boot          = true
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  depends_on = [google_project_iam_member.jump_host_container_admin]
}

# Firewall Rules for Jump Host
# Allow IAP to reach jump host on port 22 (for gcloud compute ssh --tunnel-through-iap)
resource "google_compute_firewall" "allow_iap_ssh" {
  name        = "${var.environment}-allow-iap-ssh"
  network     = var.vpc_name
  description = "Allow IAP SSH access to jump host"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google's IAP IP range
  target_tags   = ["${var.environment}-jump-host"]
}

# Allow jump host egress to cluster VPC (for kubectl and internal services)
resource "google_compute_firewall" "jump_host_to_cluster" {
  name        = "${var.environment}-jump-host-to-cluster"
  network     = var.vpc_name
  description = "Allow jump host egress to cluster VPC"
  direction   = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443", "8080"]
  }

  destination_ranges = [var.cluster_vpc_cidr]
  target_tags        = ["${var.environment}-jump-host"]
}

# OS Login IAM Binding (optional — enables OS Login for project)
# If OS Login is enabled at the project level, users can SSH using their Google identities
resource "google_project_iam_member" "os_login_admin" {
  count = var.enable_os_login_project_binding ? 1 : 0

  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "user:${var.admin_email}"
}
