module "vpc" {
  source = "../../modules/vpc"

  environment           = var.environment
  region                = var.region
  cluster_vpc_cidr      = var.cluster_vpc_cidr
  jump_host_subnet_cidr = var.jump_host_subnet_cidr
  pod_range_cidr        = var.pod_range_cidr
  service_range_cidr    = var.service_range_cidr
  enable_jump_host_nat  = var.enable_jump_host_nat
}

module "gke" {
  source = "../../modules/gke"

  environment                              = var.environment
  project_id                               = var.project_id
  region                                   = var.region
  vpc_name                                 = module.vpc.cluster_vpc_name
  private_subnet_name                      = module.vpc.cluster_private_subnet_id
  jump_host_subnet_cidr                    = var.jump_host_subnet_cidr
  pod_range_name                           = module.vpc.cluster_private_secondary_range_name
  service_range_name                       = module.vpc.cluster_services_secondary_range_name
  pod_range_cidr                           = var.pod_range_cidr
  master_ipv4_cidr_block                   = var.master_ipv4_cidr_block
  node_machine_type                        = var.node_machine_type
  node_disk_size_gb                        = var.node_disk_size_gb
  node_disk_type                           = var.node_disk_type
  node_min_size                            = var.node_min_size
  node_max_size                            = var.node_max_size
  node_locations                           = var.node_locations
  deletion_protection                      = var.gke_deletion_protection
  enable_cilium_clusterwide_network_policy = var.enable_cilium_clusterwide_network_policy
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
  enable_restricted_egress        = var.enable_restricted_jump_host_egress
  kms_key_id                      = var.kms_key_id
}

module "cloud_sql" {
  source = "../../modules/cloud_sql"
  count  = var.create_database ? 1 : 0

  environment                          = var.environment
  project_id                           = var.project_id
  region                               = var.region
  vpc_id                               = module.vpc.cluster_vpc_id
  private_service_access_address       = var.private_service_access_address
  private_service_access_prefix_length = var.private_service_access_prefix_length
  db_tier                              = var.db_tier
  db_name                              = var.db_name
  db_username                          = var.db_username
  disk_size                            = var.db_disk_size
  disk_type                            = var.db_disk_type
  disk_autoresize                      = var.db_disk_autoresize
  availability_type                    = var.db_availability_type
  backup_enabled                       = var.db_backup_enabled
  backup_start_time                    = var.db_backup_start_time
  backup_retention_count               = var.db_backup_retention_count
  deletion_protection                  = var.cloud_sql_deletion_protection
}