module "vpc" {
  source            = "../../modules/vpc"
  environment       = var.environment
  cluster_vpc_cidr  = var.cluster_vpc_cidr
  support_vpc_cidr  = var.support_vpc_cidr
  azs               = var.azs
  subnet_multiplier = var.subnet_multiplier
}

module "vpc_peering" {
  source                  = "../../modules/vpc_peering"
  cluster_vpc_id          = module.vpc.cluster_vpc_id
  support_vpc_id          = module.vpc.support_vpc_id
  cluster_vpc_cidr        = var.cluster_vpc_cidr
  support_vpc_cidr        = var.support_vpc_cidr
  cluster_route_table_ids = module.vpc.cluster_private_route_tables
  support_route_table_ids = module.vpc.support_private_route_tables
}

module "eks" {
  source                          = "../../modules/eks"
  environment                     = var.environment
  cluster_name                    = "${var.environment}-eks"
  cluster_version                 = var.cluster_version
  vpc_id                          = module.vpc.cluster_vpc_id
  private_subnets                 = module.vpc.cluster_private_subnets
  endpoint_sg_id                  = module.endpoints.endpoint_sg_id
  support_vpc_cidr                = var.support_vpc_cidr
  cluster_vpc_cidr                = var.cluster_vpc_cidr
  node_instance_types             = var.node_instance_types
  node_desired_size               = var.node_desired_size
  node_min_size                   = var.node_min_size
  node_max_size                   = var.node_max_size
  cluster_log_retention_days      = var.cluster_log_retention_days
  node_max_unavailable_percentage = var.node_max_unavailable_percentage
  jump_host_role_arn              = module.ec2_ssm.role_arn
}

module "ec2_ssm" {
  source              = "../../modules/ec2_ssm"
  environment         = var.environment
  region              = var.region
  vpc_id              = module.vpc.support_vpc_id
  subnet_ids          = module.vpc.support_private_subnets
  cluster_vpc_cidr    = var.cluster_vpc_cidr
  support_vpc_cidr    = var.support_vpc_cidr
  instance_type       = var.ssm_instance_type
  ami_name_pattern    = var.ssm_ami_name_pattern
  s3_artifacts_bucket = var.ssm_artifacts_bucket
  s3_artifacts_prefix = var.ssm_artifacts_prefix
}

module "endpoints" {
  source                       = "../../modules/endpoints"
  environment                  = var.environment
  vpc_id                       = module.vpc.cluster_vpc_id
  private_route_tables         = module.vpc.cluster_private_route_tables
  private_subnet_ids           = module.vpc.cluster_private_subnets
  region                       = var.region
  cluster_vpc_cidr             = var.cluster_vpc_cidr
  support_vpc_id               = module.vpc.support_vpc_id
  support_private_subnets      = module.vpc.support_private_subnets
  support_vpc_cidr             = var.support_vpc_cidr
  support_private_route_tables = module.vpc.support_private_route_tables
}