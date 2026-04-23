resource "aws_security_group" "endpoint_sg" {
  name   = "endpoint-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cluster_vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_tables
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.endpoint_sg.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.endpoint_sg.id]
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.endpoint_sg.id]
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.endpoint_sg.id]
}
