terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "endpoint_sg" {
  name        = "${var.environment}-endpoint-sg"
  description = "Security group for cluster VPC interface endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS from cluster VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cluster_vpc_cidr]
  }

  egress {
    description = "Allow all outbound to AWS services"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cluster_vpc_cidr]
  }

  tags = {
    Name = "${var.environment}-endpoint-sg"
  }
}

# Support VPC endpoints for SSM
resource "aws_security_group" "support_endpoint_sg" {
  name        = "${var.environment}-support-endpoint-sg"
  description = "Security group for support VPC SSM interface endpoints"
  vpc_id      = var.support_vpc_id

  ingress {
    description = "Allow HTTPS from support VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.support_vpc_cidr]
  }

  egress {
    description = "Allow all outbound to AWS services"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.support_vpc_cidr]
  }

  tags = {
    Name = "${var.environment}-support-endpoint-sg"
  }
}

locals {
  support_interface_endpoints = [
    "ssm",
    "ssmmessages",
    "ec2messages",
    "eks",
    "sts"
  ]
}

resource "aws_vpc_endpoint" "support_interface" {
  for_each = toset(local.support_interface_endpoints)

  vpc_id              = var.support_vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.support_private_subnets
  security_group_ids  = [aws_security_group.support_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_tables
}

resource "aws_vpc_endpoint" "s3_support" {
  vpc_id            = var.support_vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.support_private_route_tables

  tags = {
    Name = "${var.environment}-s3-support-endpoint"
  }
}

locals {
  interface_endpoints = [
    "ecr.api",
    "ecr.dkr",
    "logs",
    "sts",
    "ec2",
    "eks",
    "elasticloadbalancing",
    "autoscaling",
    "monitoring"
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = toset(local.interface_endpoints)
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}