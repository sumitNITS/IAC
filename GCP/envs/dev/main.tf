module "vpc" {
  source = "../../modules/vpc"

  environment           = var.environment
  region                = var.region
  cluster_vpc_cidr      = var.cluster_vpc_cidr
  jump_host_subnet_cidr = var.jump_host_subnet_cidr
  pod_range_cidr        = var.pod_range_cidr
  service_range_cidr    = var.service_range_cidr
}

module "gke" {
  source = "../../modules/gke"

  environment            = var.environment
  project_id             = var.project_id
  region                 = var.region
  vpc_name               = module.vpc.cluster_vpc_name
  private_subnet_name    = module.vpc.cluster_private_subnet_id
  jump_host_subnet_cidr  = var.jump_host_subnet_cidr
  pod_range_name         = module.vpc.cluster_private_secondary_range_name
  service_range_name     = module.vpc.cluster_services_secondary_range_name
  pod_range_cidr         = var.pod_range_cidr
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  node_machine_type      = var.node_machine_type
  node_disk_size_gb      = var.node_disk_size_gb
  node_disk_type         = var.node_disk_type
  node_min_size          = var.node_min_size
  node_max_size          = var.node_max_size
  node_locations         = var.node_locations
  deletion_protection    = var.gke_deletion_protection
}

module "compute_jump_host" {
  source = "../../modules/compute_jump_host"

  environment                     = var.environment
  project_id                      = var.project_id
  zone                            = var.zone
  vpc_name                        = module.vpc.cluster_vpc_name
  subnet_id                       = module.vpc.jump_host_subnet_id
  cluster_vpc_cidr                = var.cluster_vpc_cidr
  machine_type                    = var.jump_host_machine_type
  image                           = var.jump_host_image
  gcs_artifacts_bucket            = var.gcs_artifacts_bucket
  deletion_protection             = var.jump_host_deletion_protection
  admin_email                     = var.admin_email
  enable_os_login_project_binding = var.enable_os_login_project_binding
  kms_key_id                      = var.kms_key_id
}