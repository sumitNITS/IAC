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
      version = "~> 3.5"
    }
  }
}

# KMS for GKE Secret Encryption
resource "random_id" "kms_suffix" {
  byte_length = 4
}

resource "google_kms_key_ring" "gke" {
  name     = "${var.environment}-gke-keyring-${random_id.kms_suffix.hex}"
  location = var.region
}

resource "google_kms_crypto_key" "gke_secrets" {
  name            = "${var.environment}-gke-secrets-key"
  key_ring        = google_kms_key_ring.gke.id
  rotation_period = "7776000s" # 90 days

  purpose = "ENCRYPT_DECRYPT"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Retrieve the GKE service identity (robot account) so we don't need project_number
resource "google_project_service_identity" "gke" {
  provider = google-beta
  project  = var.project_id
  service  = "container.googleapis.com"
}

# Allow GKE service account to use the KMS key
resource "google_kms_crypto_key_iam_member" "gke_encrypt_decrypt" {
  crypto_key_id = google_kms_crypto_key.gke_secrets.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.gke.email}"
}

# Retrieve the Compute Engine service identity to allow it to encrypt/decrypt jump host disks
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_kms_crypto_key_iam_member" "compute_encrypt_decrypt" {
  crypto_key_id = google_kms_crypto_key.gke_secrets.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  # The Compute Engine Service Agent uses the format: service-[PROJECT_NUMBER]@compute-system.iam.gserviceaccount.com
  member        = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
}

# GKE Node Service Account
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.environment}-gke-nodes"
  display_name = "GKE Node Service Account"
  description  = "Service account used by GKE node VMs"
}

resource "google_project_iam_member" "node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/autoscaling.metricsWriter",
    "roles/monitoring.viewer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Allow nodes to pull private images from Artifact Registry in this project
resource "google_project_iam_member" "node_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  provider = google-beta

  name     = "${var.environment}-gke"
  location = var.region # Regional cluster = multi-zone HA automatically

  network    = var.vpc_name
  subnetwork = var.private_subnet_name

  # Release channel (Regular = tested, stable Kubernetes versions)
  release_channel {
    channel = "REGULAR"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true # ONLY private IP for control plane
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = false
    }
  }

  # Authorized networks restrict access to the private control plane endpoint.
  # Without this block, the private endpoint is reachable from the entire VPC.
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.jump_host_subnet_cidr # Renamed for semantic clarity
      display_name = "jump-host-subnet"
    }
  }

  # IP allocation (VPC-native, similar to VPC-CNI)
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.service_range_name
  }

  # Remove default node pool — we'll define our own
  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  # Secret encryption (same as EKS KMS encryption)
  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.gke_secrets.id
  }

  # Workload Identity (equivalent to IRSA)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable Dataplane V2 for eBPF-based networking and security
  datapath_provider = "ADVANCED_DATAPATH"

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
    managed_prometheus {
      enabled = true
    }
  }

  # Cost management
  cost_management_config {
    enabled = true
  }

  resource_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  deletion_protection = var.deletion_protection

  depends_on = [google_kms_crypto_key_iam_member.gke_encrypt_decrypt]
}

# GKE Node Pool
resource "google_container_node_pool" "primary" {
  provider = google-beta

  name     = "${var.environment}-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  autoscaling {
    min_node_count = var.node_min_size
    max_node_count = var.node_max_size
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type
    boot_disk_kms_key = google_kms_crypto_key.gke_secrets.id

    service_account = google_service_account.gke_nodes.email

    # Artifact Registry requires the cloud-platform scope. 
    # Permissions are safely restricted by the attached IAM service account.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Metadata protection (equivalent to IMDSv2)
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded VM options
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    tags = ["${var.environment}-gke-node"]

    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  node_locations = var.node_locations

  depends_on = [
    google_project_iam_member.node_roles,
    google_project_iam_member.node_artifact_registry_reader,
    google_kms_crypto_key_iam_member.compute_encrypt_decrypt
  ]
}

# Firewall Rules for GKE
# GKE auto-creates node-to-node and master-to-node rules, but we add explicit
# ones here for visibility and to avoid relying solely on GKE-managed rules.

# 1. GKE control plane -> nodes (kubelet + API webhook callbacks)
resource "google_compute_firewall" "allow_gke_master" {
  name        = "${var.environment}-allow-gke-master"
  network     = var.vpc_name
  description = "Allow GKE control plane to reach nodes (kubelet 10250, webhooks 443, 8443, 9443)"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443", "10250", "8443", "9443"]
  }

  source_ranges = [var.master_ipv4_cidr_block]
  target_tags   = ["${var.environment}-gke-node"]
}

# 2. GCP Load Balancer health checks -> nodes (NodePort / Ingress health checks)
resource "google_compute_firewall" "allow_gke_health_checks" {
  name        = "${var.environment}-allow-gke-health-checks"
  network     = var.vpc_name
  description = "Allow GCP LB health check probes to GKE nodes"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "10256", "30000-32767"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_tags = ["${var.environment}-gke-node"]
}

# 3. DNS (CoreDNS) — pod range to nodes UDP/TCP 53
# Pod-to-pod traffic is handled by GKE CNI auto-rules, but CoreDNS runs on
# nodes and needs explicit access from the pod IP range.
resource "google_compute_firewall" "allow_gke_dns" {
  name        = "${var.environment}-allow-gke-dns"
  network     = var.vpc_name
  description = "Allow pods to reach CoreDNS on nodes"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  source_ranges = [var.pod_range_cidr]
  target_tags   = ["${var.environment}-gke-node"]
}
