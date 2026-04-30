# AWS Development Environment Configuration

This directory contains the Terraform configuration to provision a secure, highly available, private-first AWS infrastructure for the **dev** environment.

## Architecture Overview

This environment uses a dual-VPC architecture to isolate operational access from workloads:

1.  **Cluster VPC (`10.10.0.0/16`)**:
    *   Hosts the **Amazon EKS Cluster** (Multi-AZ, private-first).
    *   Segmented into Public, Private (for EKS Nodes), and DB (for RDS) subnets.
    *   Uses VPC Endpoints to communicate securely with AWS services (e.g., S3).
2.  **Support VPC (`10.20.0.0/16`)**:
    *   Hosts an **EC2 Jump Host** accessible *only* via AWS Systems Manager (SSM) Session Manager.
    *   Contains its own VPC Endpoints (SSM, EC2Messages, SSMMessages) to allow SSM access without requiring public IP addresses or Internet Gateways.
3.  **VPC Peering**:
    *   Securely connects the Support VPC and Cluster VPC.
    *   Allows the SSM Jump Host to execute `kubectl` commands against the private EKS cluster API and connect to internal RDS instances.

## Key Components

- **Amazon EKS (`module.eks`)**: Secure Kubernetes cluster with an OIDC provider for IAM Roles for Service Accounts (IRSA). Restricted control plane access via security groups.
- **EC2 SSM Jump Host (`module.ec2_ssm`)**: Amazon Linux 2023 instance running the SSM agent. Pre-configured with IAM roles to read S3 artifacts and describe EKS clusters.
- **VPC Endpoints (`module.endpoints`)**: Eliminates the need to traverse the public internet for AWS API calls (SSM, S3, etc.).

## 3-Tier Architecture Model

This infrastructure is designed to host applications following a classic, secure 3-tier architecture. The network is explicitly segmented to support the isolation of each tier.

```text
      [ Internet / Users ]
               │
               ▼
 ┌─────────────────────────────────────────────────────────┐
 │  AWS Cloud                                              │
 │                                                         │
 │  ┌───────────────────────────────────────────────────┐  │
 │  │ Cluster VPC (10.10.0.0/16)                        │  │
 │  │                                                   │  │
 │  │  [Tier 1: Presentation]                           │  │
 │  │  ├── Public Subnets                               │  │
 │  │  └── Application Load Balancer / Ingress          │  │
 │  │           │                                       │  │
 │  │           ▼                                       │  │
 │  │  [Tier 2: Application]                            │  │
 │  │  ├── Private Subnets                              │  │
 │  │  └── EKS Nodes & Application Pods                 │  │
 │  │           │                                       │  │
 │  │           ▼                                       │  │
 │  │  [Tier 3: Data]                                   │  │
 │  │  ├── DB Subnets                                   │  │
 │  │  └── RDS Database                                 │  │
 │  └───────────────────────────────────────────────────┘  │
 │           ▲                                             │
 │           │ VPC Peering                                 │
 │           ▼                                             │
 │  ┌───────────────────────────────────────────────────┐  │
 │  │ Support VPC (10.20.0.0/16) - Operational Access   │  │
 │  │  └── SSM Jump Host (EC2)                          │  │
 │  └───────────────────────────────────────────────────┘  │
 └─────────────────────────────────────────────────────────┘
```

-   **Tier 1: Presentation (Web Tier)**: Resides in the `cluster_public_subnets`. This is where public-facing resources like Application Load Balancers (ALBs) that manage Kubernetes Ingress are deployed. They are the only components exposed to the internet.
-   **Tier 2: Application (Logic Tier)**: The EKS cluster nodes and application pods run in the `cluster_private_subnets`. They are completely isolated from the internet and only accept traffic from the Presentation Tier.
-   **Tier 3: Data (Database Tier)**: Databases (e.g., Amazon RDS) are placed in the dedicated `cluster_db_subnets`. These subnets have the most restrictive network rules, typically only allowing access from the Application Tier.

## How to Access

Because the environment is strictly private, you must proxy your access through the SSM Jump Host. After a successful `terraform apply`, Terraform will output the exact commands you need:

**1. Access the Jump Host via SSM:**
```bash
$(terraform output -raw ssm_session_command)
```

**2. Configure `kubectl` (run this *inside* the jump host):**
```bash
$(terraform output -raw kubectl_config_command)
```

## Structure

- `main.tf` — Module instantiation and wiring
- `variables.tf` — Variable definitions with descriptions and types
- `outputs.tf` — Comprehensive outputs from all modules for downstream usage
- `provider.tf` — AWS provider configuration with version constraints
- `backend.tf` — Terraform state backend (S3 + DynamoDB)

## State Management

State is managed securely using an **S3 Backend** with encryption enabled, and a **DynamoDB table** for state locking to prevent consistency issues.

## Best Practices Followed

- Variables have descriptions and types
- Outputs documented for downstream consumption
- Provider version constraints specified
- State backend encrypted and locked
- Common tags managed centrally
- Module dependencies explicit
- Private-first security model
- High availability (Multi-AZ EKS node distribution)
- VPC Endpoints for private AWS service access (no internet required)
- Comprehensive outputs for CLI commands
- Lifecycle configurations to prevent unintended resource replacements (e.g., Jump Host AMIs)

## Room for Improvement (Production Readiness)

While this setup follows several best practices for a development environment, the following enhancements are recommended before promoting this architecture to production:

- **High Availability for Jump Host**: Convert the standalone EC2 SSM Jump Host into an Auto Scaling Group (ASG) with a desired capacity of 1. This ensures self-healing and uninterrupted operational access if the instance or its Availability Zone fails.
- **Stricter IAM Policies**: Scope down IAM permissions (e.g., `eks:DescribeCluster`) to specific resource ARNs rather than using wildcards (`*`).
- **Tighter Network Egress**: Restrict Security Group egress rules on the Jump Host to target strictly the EKS control plane security group, rather than allowing HTTPS to the entire cluster VPC CIDR.
- **Partial Backend Configuration**: Remove placeholder values in `backend.tf` and migrate to partial backend configuration (via `terraform init -backend-config=...`) to avoid hardcoding infrastructure details in version control.
