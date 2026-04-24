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
  mult = var.subnet_multiplier
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_vpc" "cluster" {
  cidr_block           = var.cluster_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  count                   = length(var.azs) * local.mult
  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = cidrsubnet(var.cluster_vpc_cidr, 8, count.index)
  availability_zone       = element(var.azs, count.index % length(var.azs))
  map_public_ip_on_launch = true
  tags                    = { "kubernetes.io/role/elb" = "1" }
}

resource "aws_subnet" "private" {
  count             = length(var.azs) * local.mult
  vpc_id            = aws_vpc.cluster.id
  cidr_block        = cidrsubnet(var.cluster_vpc_cidr, 8, count.index + 50)
  availability_zone = element(var.azs, count.index % length(var.azs))
  tags              = { "kubernetes.io/role/internal-elb" = "1" }
}

resource "aws_subnet" "db" {
  count             = length(var.azs) * local.mult
  vpc_id            = aws_vpc.cluster.id
  cidr_block        = cidrsubnet(var.cluster_vpc_cidr, 8, count.index + 100)
  availability_zone = element(var.azs, count.index % length(var.azs))
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.cluster.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "pub" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.cluster.id
}

resource "aws_route_table_association" "priv" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % length(var.azs)].id
}

resource "aws_cloudwatch_log_group" "cluster_flow" {
  name              = "/aws/vpc/flowlogs/cluster-${var.environment}"
  retention_in_days = 365
}

resource "aws_flow_log" "cluster" {
  vpc_id               = aws_vpc.cluster.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.cluster_flow.arn
}

# Support VPC
resource "aws_vpc" "support" {
  cidr_block           = var.support_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "support_private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.support.id
  cidr_block        = cidrsubnet(var.support_vpc_cidr, 8, count.index)
  availability_zone = element(var.azs, count.index)
}

resource "aws_route_table" "support_private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.support.id
}

resource "aws_route_table_association" "support_assoc" {
  count          = length(aws_subnet.support_private)
  subnet_id      = aws_subnet.support_private[count.index].id
  route_table_id = aws_route_table.support_private[count.index].id
}