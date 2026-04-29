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
