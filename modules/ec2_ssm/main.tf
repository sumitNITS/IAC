terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.environment}-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "eks_access" {
  name = "${var.environment}-ec2-eks-access"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "s3_artifacts_read" {
  count = var.s3_artifacts_bucket == null ? 0 : 1

  name = "${var.environment}-ec2-s3-artifacts-read"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      merge(
        {
          Sid    = "ListArtifactsBucket"
          Effect = "Allow"
          Action = [
            "s3:ListBucket"
          ]
          Resource = "arn:aws:s3:::${var.s3_artifacts_bucket}"
        },
        var.s3_artifacts_prefix == null ? {} : {
          Condition = {
            StringLike = {
              "s3:prefix" = [
                var.s3_artifacts_prefix,
                "${var.s3_artifacts_prefix}/*"
              ]
            }
          }
        }
      ),
      {
        Sid    = "ReadArtifactsObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = (
          var.s3_artifacts_prefix == null
          ? "arn:aws:s3:::${var.s3_artifacts_bucket}/*"
          : "arn:aws:s3:::${var.s3_artifacts_bucket}/${var.s3_artifacts_prefix}/*"
        )
      }
    ]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}

resource "aws_security_group" "sg" {
  name        = "${var.environment}-ssm-sg"
  description = "Security group for SSM jump host - restricts egress to VPC CIDRs only"
  vpc_id      = var.vpc_id

  # DNS resolution
  egress {
    description = "Allow DNS (UDP 53)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.support_vpc_cidr]
  }

  # HTTPS to AWS endpoints and cluster services
  egress {
    description = "Allow HTTPS to AWS endpoints and cluster services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.support_vpc_cidr, var.cluster_vpc_cidr]
  }

  # RDS access
  egress {
    description = "Allow PostgreSQL access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.cluster_vpc_cidr]
  }

  tags = {
    Name = "${var.environment}-ssm-sg"
  }
}

resource "aws_security_group_rule" "s3_https_egress" {
  type              = "egress"
  description       = "Allow HTTPS to S3 via Gateway endpoint"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
  security_group_id = aws_security_group.sg.id
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }
}

resource "aws_instance" "ssm" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.sg.id]
  iam_instance_profile        = aws_iam_instance_profile.profile.name
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF

  tags = {
    Name = "${var.environment}-ssm-jump-host"
  }
}
