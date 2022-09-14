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
  vpc_name            = module.subnets.vpc_name
  vpc_subnets         = module.subnets.subnets
  vpc_subnet_count    = module.subnets.count
  cos_id              = module.cos.id
  common_tags = var.common_tags
  tags = ["openshift"]
}

resource "local_file" "cluster_creds" {
  filename = ".cluster_creds"
  content = jsonencode({
    server_url = module.cluster.server_url
    username = module.cluster.username
    password = module.cluster.password
    token = module.cluster.token
  })
}
