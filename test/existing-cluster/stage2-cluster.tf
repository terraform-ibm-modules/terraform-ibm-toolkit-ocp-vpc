module "cluster" {
  source = "./module"

  resource_group_name = module.resource_group.name
  region              = var.region
  ibmcloud_api_key    = var.ibmcloud_api_key
  name                = var.cluster_name
  worker_count        = var.worker_count
  exists              = var.cluster_exists
  name_prefix         = var.name_prefix
  vpc_name            = ""
  vpc_subnets         = []
  vpc_subnet_count    = var.vpc_subnet_count
  cos_id              = ""
}


resource null_resource print_resources {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
  provisioner "local-exec" {
    command = "echo 'Total Workers: ${module.cluster.total_worker_count}'"
  }
  provisioner "local-exec" {
    command = "echo 'Workers: ${jsonencode(module.cluster.workers)}'"
  }
}