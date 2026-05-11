# Google Cloud Platform Infrastructure

This directory contains the Terraform configuration to provision a secure, highly available, private-first GCP infrastructure for containerised workloads.

## Architecture Overview

This environment uses a **single VPC architecture** with logical subnet isolation to separate operational access from workloads:

1.  **Cluster VPC**:
    *   Hosts the **Google Kubernetes Engine (GKE) Cluster** (Regional, private nodes).
    *   Segmented into a **Private Subnet** (for GKE nodes) with secondary IP ranges for Pods and Services, and a dedicated **Jump Host Subnet** for operational access.
    *   Uses **Cloud NAT** scoped to the private subnet to allow GKE nodes outbound internet access (required for GCE Ingress controller image pulls) without public IPs.
2.  **Jump Host Subnet**:
    *   Hosts a **Compute Engine Jump Host** accessible *only* via **Identity-Aware Proxy (IAP)**.
    *   Has no external IP address. Access is gated through Google's IAP infrastructure.
    *   Uses **Cloud NAT** (optionally scoped) for outbound internet access to download tools and updates.
3.  **Private Service Access**:
    *   Securely connects the Cluster VPC to **Cloud SQL** via VPC peering (`servicenetworking.googleapis.com`).
    *   The database has no public IP; it is reachable only from within the VPC.

## Key Components

- **Google GKE (`module.gke`)**: Secure Kubernetes cluster with Workload Identity (equivalent to IRSA), KMS-encrypted secrets, Dataplane V2 (eBPF-based networking), and Shielded VM nodes. The control plane is fully private (`enable_private_endpoint = true`), accessible only from the jump host subnet via **master authorized networks**.
- **Compute Engine IAP Jump Host (`module.compute_jump_host`)**: Debian/Ubuntu VM with OS Login enabled. Pre-configured with IAM roles to interact with the GKE cluster and read GCS artifacts. Accessed via `gcloud compute ssh --tunnel-through-iap`.
- **Cloud SQL (`module.cloud_sql`)**: Private PostgreSQL 15 instance with automated backups, Query Insights, and KMS encryption. Connected via Private Service Access.
- **VPC (`module.vpc`)**: Custom mode VPC with VPC Flow Logs, Cloud Router & NAT for GKE, and optional NAT for the jump host.

## 3-Tier Architecture Model

This infrastructure is designed to host applications following a classic, secure 3-tier architecture. The network is explicitly segmented to support the isolation of each tier.

```text
      [ Internet / Users ]
               │
               ▼
 ┌─────────────────────────────────────────────────────────┐
 │  GCP Project                                            │
 │                                                         │
 │  ┌───────────────────────────────────────────────────┐  │
 │  │ Cluster VPC                                       │  │
 │  │                                                   │  │
 │  │  [Tier 1: Presentation]                           │  │
 │  │  └── Public-facing Ingress / Load Balancer        │  │
 │  │           │                                       │  │
 │  │           ▼                                       │  │
 │  │  [Tier 2: Application]                            │  │
 │  │  ├── Private Subnet                               │  │
 │  │  └── GKE Nodes & Application Pods                 │  │
 │  │           │                                       │  │
 │  │           ▼                                       │  │
 │  │  [Tier 3: Data]                                   │  │
 │  │  └── Cloud SQL (via Private Service Access)       │  │
 │  └───────────────────────────────────────────────────┘  │
 │           ▲                                             │
 │           │ IAP Tunnel                                  │
 │           ▼                                             │
 │  ┌───────────────────────────────────────────────────┐  │
 │  │ Jump Host Subnet — Operational Access             │  │
 │  │  └── Compute Engine Jump Host (IAP)               │  │
 │  └───────────────────────────────────────────────────┘  │
 └─────────────────────────────────────────────────────────┘
```

-   **Tier 1: Presentation (Web Tier)**: Public-facing traffic enters through GCP Load Balancers (e.g., GCE Ingress) which terminate SSL and forward to Kubernetes services. Only the load balancer frontends are exposed to the internet.
-   **Tier 2: Application (Logic Tier)**: The GKE cluster nodes and application pods run in the **private subnet**. They have no external IPs and only accept traffic from the Presentation Tier or authorized internal sources.
-   **Tier 3: Data (Database Tier)**: The **Cloud SQL** instance resides in a dedicated peering range allocated via Private Service Access. It has no public IP and is reachable only from within the Cluster VPC.

## How to Access

Because the GKE control plane is fully private, you must proxy your access through the IAP Jump Host. After a successful `terraform apply`, Terraform will output the exact commands you need:

**1. SSH into the Jump Host via IAP:**
```bash
$(terraform output -raw iap_ssh_command)
```

**2. Configure `kubectl` (run this *inside* the jump host):**
```bash
$(terraform output -raw kubectl_config_command)
```

**3. Connect to Cloud SQL (from the jump host or a GKE pod):**
Use the Cloud SQL private IP (`terraform output -raw cloud_sql_private_ip`) or the Cloud SQL Auth Proxy.

## State Management

State is managed securely using a **GCS Backend** with:
- **Versioning enabled** — protects against accidental overwrites.
- **Uniform bucket-level access** — simplifies IAM and prevents ACL bypass.
- **Public access prevention** — enforces private-only access.
- **Lifecycle rules** — automatically delete archived versions after 10 newer versions exist.

The backend is bootstrapped via the `backend/` directory, which also creates a dedicated **Terraform Service Account** with the minimum required roles. The admin user impersonates this service account to run Terraform.

## Best Practices Followed

- Variables have descriptions and types
- Outputs documented for downstream consumption
- Provider version constraints specified (`~> 5.0`)
- State backend encrypted and versioned
- Common labels managed centrally (`environment`, `managed_by`)
- Module dependencies explicit (`depends_on`)
- Private-first security model (private GKE endpoint, no external IPs on nodes)
- High availability (Regional GKE cluster with multi-zone node pool)
- Shielded VMs with secure boot and integrity monitoring
- KMS encryption at rest for GKE secrets, jump host disks, and Cloud SQL
- Workload Identity enabled for fine-grained pod IAM (equivalent to IRSA)
- Master Authorized Networks restrict control plane access to the jump host subnet
- VPC Flow Logs enabled on all subnets for auditability
- Cloud NAT scoped per subnet (GKE nodes get restricted NAT; jump host gets optional separate NAT)
- Comprehensive outputs for CLI commands (`kubectl`, `gcloud compute ssh`)
- Cilium ClusterWide Network Policies enabled (Dataplane V2) for cross-namespace network policies

## Room for Improvement (Production Readiness)

While this setup follows several best practices for a development environment, the following enhancements are recommended before promoting this architecture to production:

- **High Availability for Jump Host**: Convert the standalone Compute Engine instance into a **Managed Instance Group (MIG)** with a desired size of 1. This ensures self-healing and uninterrupted operational access if the instance or its zone fails.
- **Stricter IAM Policies**: Scope down IAM permissions (e.g., `roles/container.developer`) to specific cluster resources rather than project-wide access. Consider custom roles for the Terraform service account.
- **Tighter Network Egress**: Restrict the jump host's firewall egress rules to target strictly the GKE master CIDR block and Cloud SQL private range, rather than the entire cluster VPC CIDR.
- **Cloud SQL HA**: Enable Cloud SQL High Availability (`availability_type = "REGIONAL"`) if not already configured, to provide automatic failover across zones.
- **Cloud SQL IAM Authentication**: Move from native PostgreSQL passwords to Cloud SQL IAM database authentication for improved auditability and credential rotation.
