terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "cluster" {
  name = "${var.environment}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "eks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

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
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.environment}-eks-encryption-key"
  }
}

resource "aws_cloudwatch_log_group" "cluster_logs" {
  name              = "/aws/eks/${var.cluster_name}"
  retention_in_days = var.cluster_log_retention_days
  kms_key_id        = aws_kms_key.eks.arn

  tags = {
    Name = "${var.cluster_name}-logs"
  }
}

# --- Cluster Security Group (restrictive) ---
resource "aws_security_group" "cluster" {
  name_prefix = "${var.environment}-cluster-sg"
  description = "EKS cluster security group - restricts API access to VPC CIDRs only"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS from support VPC (SSM jump host)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.support_vpc_cidr]
  }

  ingress {
    description = "Allow HTTPS from cluster VPC (nodes/pods)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cluster_vpc_cidr]
  }

  egress {
    description = "Allow all outbound to cluster VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cluster_vpc_cidr]
  }

  tags = {
    Name = "${var.environment}-cluster-sg"
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.cluster.id] #var.endpoint_sg_id
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_cloudwatch_log_group.cluster_logs,
    aws_iam_role_policy_attachment.cluster
  ]
}

# --- OIDC Provider for IRSA ---
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# --- Node Security Group (proper rules) ---
resource "aws_security_group" "node_sg" {
  name_prefix = "${var.environment}-node-sg"
  description = "EKS node security group - allows control plane and inter-node traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow pods from cluster control plane"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  ingress {
    description     = "Allow kubelet from cluster control plane"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  ingress {
    description = "Allow inter-node TCP communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow inter-node UDP communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    self        = true
  }

egress {
  description = "Allow VPC internal"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    var.cluster_vpc_cidr,
    var.support_vpc_cidr
    ]
}

egress {
  description     = "Allow HTTPS to VPC endpoints"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  security_groups = [var.endpoint_sg_id]
}

  tags = {
    Name = "${var.environment}-node-sg"
  }
}

# ============================================================
# EKS Node IAM Role and Policies
# ============================================================

resource "aws_iam_role" "node_role" {
  name = "${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.environment}-eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_instance_profile" "node_profile" {
  name = "${var.environment}-eks-node-profile"
  role = aws_iam_role.node_role.name
}

# --- Launch Template for Node Group ---
resource "aws_launch_template" "nodes" {
  name_prefix = "${var.environment}-eks-node-"

  vpc_security_group_ids = [aws_security_group.node_sg.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-eks-node"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.environment}-eks-node-volume"
    }
  }
}

# --- Managed Node Group ---
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.environment}-ng"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.private_subnets
  instance_types  = var.node_instance_types

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable_percentage = var.node_max_unavailable_percentage
  }

  tags = {
    Name = "${var.environment}-eks-node"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_CloudWatchAgentServerPolicy,
  ]
}

# ============================================================
# EKS Managed Add-ons
# ============================================================

data "aws_eks_addon_version" "latest" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy"])

  addon_name         = each.value
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "this" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy"])

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value
  addon_version               = data.aws_eks_addon_version.latest[each.value].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_node_group.nodes]
}
