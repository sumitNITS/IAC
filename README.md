# Multi-Cloud Infrastructure as Code (IaC)

This repository contains the Terraform configurations required to provision secure, highly available, and private-first cloud infrastructure across both **Amazon Web Services (AWS)** and **Google Cloud Platform (GCP)**.

The primary intention of this project is to provide a production-ready baseline for hosting robust **3-tier applications** using managed Kubernetes services (Amazon EKS and Google GKE). The architecture enforces strict network isolation, automated security, and modern DevOps practices.

## Core Architectural Principles

- **Private-First Networks:** Workload clusters (EKS/GKE) are deployed within private subnets featuring private control planes. There is no direct inbound internet access to the application or data tiers.
- **Operational Isolation:** Administrative access is strictly decoupled from the application network. Infrastructure is accessed via dedicated Support VPCs and managed Jump Hosts (e.g., AWS Systems Manager) connected over secure VPC peering.
- **Least Privilege:** Granular IAM Roles (AWS) and Service Accounts (GCP) are applied universally. Pod-level permissions are managed securely via Workload Identity (GCP) and IRSA (AWS).
- **Encryption Everywhere:** All state files, storage volumes, and Kubernetes secrets are encrypted at rest.

## Repository Structure

The repository is logically divided into cloud-specific deployments and reusable modules:

### ☁️ AWS Configurations

AWS deployments are managed through root configurations and shared modules:
- **`AWS/envs/`**: Environment-specific root modules (e.g., `AWS/envs/dev/` containing architecture diagrams and deployment instructions).
- **`AWS/modules/`**: Reusable AWS Terraform modules:
  - `vpc`: Configures Cluster and Support VPCs with explicit 3-tier subnets (Public, Private, DB).
  - `vpc_peering`: Establishes secure connectivity between Support and Cluster VPCs.
  - `endpoints`: Sets up VPC Endpoints (S3, SSM) for private AWS API access.
  - `eks`: Provisions a private-first EKS cluster with managed node groups and IRSA.
  - `ec2_ssm`: Provisions a secure EC2 Jump Host accessible via SSM for operational tasks.

### ☁️ GCP Configurations

Google Cloud resources are securely isolated in their own directory:
- **`GCP/backend/`**: Bootstrap configurations for robust Terraform state management (GCS Buckets, Service Account impersonation).
- **`GCP/modules/`**: Reusable GCP Terraform modules (e.g., `gke` featuring Dataplane V2 and Shielded VMs).

## Prerequisites

To deploy or manage these environments, you will need the following tools configured locally:

- Terraform (`~> 1.5.0`)
- AWS CLI (for AWS interactions)
- Google Cloud SDK (`gcloud`) (for GCP interactions)
- `kubectl` (for Kubernetes cluster management)

## Getting Started

1. Choose your target cloud provider (AWS or GCP).
2. Navigate to the respective backend or environment directory (e.g., `cd AWS/envs/dev`).
3. Follow the specific `README.md` instructions within that directory to initialize the backend and apply the infrastructure.
