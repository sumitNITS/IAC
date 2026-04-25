terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  cluster_name = var.cluster_name
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS Service"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.environment}-eks-encryption-key"
  }
}

# ============================================================
# EKS Cluster (via community module)
# ============================================================

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  # Control plane logging
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_days

  # Secret encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # IRSA / OIDC
  enable_irsa = true

  # EKS Managed Add-ons
  cluster_addons = {
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    }
  }

  # Managed Node Group
  eks_managed_node_groups = {
    default = {
      name           = "${var.environment}-ng"
      instance_types = var.node_instance_types
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"

      desired_size = var.node_desired_size
      min_size     = var.node_min_size
      max_size     = var.node_max_size

      max_unavailable_percentage = var.node_max_unavailable_percentage

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }
    }
  }

  tags = {
    Name = local.cluster_name
  }
}

# ============================================================
# Additional Security Group Rules
# ============================================================

# Support VPC -> EKS API
resource "aws_security_group_rule" "support_vpc_k8s_api" {
  security_group_id = module.cluster.cluster_security_group_id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS from support VPC (SSM jump host)"
  protocol          = "tcp"
  cidr_blocks       = [var.support_vpc_cidr]
}

# Cluster VPC -> EKS API
resource "aws_security_group_rule" "cluster_vpc_k8s_api" {
  security_group_id = module.cluster.cluster_security_group_id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS from cluster VPC (nodes/pods)"
  protocol          = "tcp"
  cidr_blocks       = [var.cluster_vpc_cidr]
}

# Node SG: Allow all intra-VPC egress
resource "aws_security_group_rule" "node_vpc_internal" {
  security_group_id = module.cluster.node_security_group_id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  description       = "Allow VPC internal"
  protocol          = "-1"
  cidr_blocks       = [var.cluster_vpc_cidr, var.support_vpc_cidr]
}

# Node SG: Allow HTTPS to VPC endpoints
resource "aws_security_group_rule" "node_to_endpoints" {
  security_group_id        = module.cluster.node_security_group_id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  description              = "Allow HTTPS to VPC endpoints"
  protocol                 = "tcp"
  source_security_group_id = var.endpoint_sg_id
}
