module "cluster" {
  source = "./module"

  resource_group_name = module.resource_group.name
  region              = var.region
  ibmcloud_api_key    = var.ibmcloud_api_key
  name                = var.cluster_name
  worker_count        = var.worker_count
  ocp_version         = var.ocp_version
  exists              = var.cluster_exists
  name_prefix         = var.name_prefix
  vpc_name            = module.vpc.name
  vpc_subnet_label_counts = module.vpc.subnet_label_counts
  vpc_subnets         = module.vpc.subnets
  vpc_subnet_label    = var.vpc_subnet_label
  cos_id              = module.cos.id
}
