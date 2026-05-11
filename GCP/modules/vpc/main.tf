terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Cluster VPC
resource "google_compute_network" "cluster" {
  name                    = "${var.environment}-cluster-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.environment}-cluster-private"
  ip_cidr_range = cidrsubnet(var.cluster_vpc_cidr, 8, 50)
  region        = var.region
  network       = google_compute_network.cluster.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pod_range_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.service_range_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Jump Host Subnet
resource "google_compute_subnetwork" "jump_host" {
  name          = "${var.environment}-jump-host"
  ip_cidr_range = var.jump_host_subnet_cidr
  region        = var.region
  network       = google_compute_network.cluster.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Firewall Rules — Jump Host Isolation
resource "google_compute_firewall" "jump_host_allow_internal" {
  name        = "${var.environment}-jump-host-allow-internal"
  network     = google_compute_network.cluster.name
  description = "Allow DNS and ICMP within jump host subnet (no broad port access)"

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.jump_host_subnet_cidr]
  target_tags   = ["${var.environment}-jump-host"]
}

# Cloud Router & NAT — for GKE nodes (required for GCE Ingress controller)
resource "google_compute_router" "gke" {
  name    = "${var.environment}-gke-router"
  region  = var.region
  network = google_compute_network.cluster.id
}

resource "google_compute_router_nat" "gke" {
  name   = "${var.environment}-gke-nat"
  router = google_compute_router.gke.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Cloud Router & NAT — scoped ONLY to the jump host subnet
# This gives the jump host outbound internet access (for tools, updates).
# GKE nodes have their own restricted NAT (HTTPS/DNS only); Cloud SQL
# remains fully private with no internet access.
resource "google_compute_router" "jump_host" {
  count   = var.enable_jump_host_nat ? 1 : 0
  name    = "${var.environment}-jump-host-router"
  region  = var.region
  network = google_compute_network.cluster.id
}

resource "google_compute_router_nat" "jump_host" {
  count  = var.enable_jump_host_nat ? 1 : 0
  name   = "${var.environment}-jump-host-nat"
  router = google_compute_router.jump_host[0].name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.jump_host.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
