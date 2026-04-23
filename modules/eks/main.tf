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

# CloudWatch Log Group for EKS cluster logging
resource "aws_cloudwatch_log_group" "cluster_logs" {
  name              = "/aws/eks/${var.cluster_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.cluster_name}-logs"
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  # Enable all cluster logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_cloudwatch_log_group.cluster_logs,
    aws_iam_role_policy_attachment.cluster
  ]
}

# Dummy SG output placeholder for RDS wiring
resource "aws_security_group" "node_sg" {
  name_prefix = "${var.environment}-node-sg"
  vpc_id      = data.aws_vpc.selected.id
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

# Required policy for EKS worker nodes
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

# Required for networking (VPC CNI plugin)
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

# Required for pulling images from ECR
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

# Required for CloudWatch Container Insights
resource "aws_iam_role_policy_attachment" "node_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_role.name
}

# Instance profile for EC2 nodes
resource "aws_iam_instance_profile" "node_profile" {
  name = "${var.environment}-eks-node-profile"
  role = aws_iam_role.node_role.name
}

data "aws_vpc" "selected" {
  id = aws_eks_cluster.this.vpc_config[0].vpc_id
}
