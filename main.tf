
locals {
  config_values = {
    4.4  = {
      type      = "openshift"
      type_code = "ocp4"
      version   = "4.4"
    }
    4.5  = {
      type      = "openshift"
      type_code = "ocp4"
      version   = "4.5"
    }
    4.6  = {
      type      = "openshift"
      type_code = "ocp4"
      version   = "4.6"
    }
  }
  cluster_config_dir    = "${path.cwd}/.kube"
  cluster_config        = "${local.cluster_config_dir}/config"
  cluster_type_file     = "${path.cwd}/.tmp/cluster_type.val"
  name_prefix           = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name_list             = [local.name_prefix, "cluster"]
  cluster_name          = var.name != "" ? var.name : join("-", local.name_list)
  tmp_dir               = "${path.cwd}/.tmp"
  config_namespace      = "default"
  server_url            = data.ibm_container_vpc_cluster.config.public_service_endpoint_url
  ingress_hostname      = data.ibm_container_vpc_cluster.config.ingress_hostname
  tls_secret            = data.ibm_container_vpc_cluster.config.ingress_secret
  openshift_versions    = {
  for version in data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions:
  substr(version, 0, 3) => "${version}_openshift"
  }
  cluster_regex         = "(${join("|", keys(local.config_values))}|ocp4).*"
  cluster_type_cleaned  = regex(local.cluster_regex, var.ocp_version)[0] == "ocp4" ? "4.6" : regex(local.cluster_regex, var.ocp_version)[0]
  cluster_type          = local.config_values[local.cluster_type_cleaned].type
  # value should be ocp4, ocp3, or kubernetes
  cluster_type_code     = local.config_values[local.cluster_type_cleaned].type_code
  cluster_type_tag      = local.cluster_type == "kubernetes" ? "iks" : "ocp"
  cluster_version       = local.cluster_type == "openshift" ? local.openshift_versions[local.config_values[local.cluster_type_cleaned].version] : ""
  ibmcloud_release_name = "ibmcloud-config"
  vpc_subnet_count      = var.vpc_subnet_count
  vpc_id                = !var.exists ? data.ibm_is_vpc.vpc[0].id : ""
  vpc_subnets           = !var.exists ? var.vpc_subnets : []
}

resource null_resource create_dirs {
  provisioner "local-exec" {
    command = "echo 'regex: ${local.cluster_regex}'"
  }
  provisioner "local-exec" {
    command = "echo 'cluster_type_cleaned: ${local.cluster_type_cleaned}'"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.cluster_config_dir}"
  }
}

resource null_resource print_resources {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
  provisioner "local-exec" {
    command = "echo 'Cos id: ${var.cos_id}'"
  }
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
}

resource null_resource print_subnets {
  provisioner "local-exec" {
    command = "echo 'VPC subnet count: ${local.vpc_subnet_count}'"
  }
  provisioner "local-exec" {
    command = "echo 'VPC subnets: ${jsonencode(local.vpc_subnets)}'"
  }
}

data ibm_resource_group resource_group {
  depends_on = [null_resource.print_resources]

  name = var.resource_group_name
}

data ibm_container_cluster_versions cluster_versions {
  depends_on = [null_resource.create_dirs]

  resource_group_id = data.ibm_resource_group.resource_group.id
}

data ibm_is_vpc vpc {
  count = !var.exists ? 1 : 0
  depends_on = [null_resource.print_resources]

  name  = var.vpc_name
}

resource ibm_container_vpc_cluster cluster {
  count = !var.exists ? 1 : 0
  depends_on = [null_resource.print_resources]

  name              = local.cluster_name
  vpc_id            = local.vpc_id
  flavor            = var.flavor
  worker_count      = var.worker_count
  kube_version      = local.cluster_version
  entitlement       = var.ocp_entitlement
  cos_instance_crn  = var.cos_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  disable_public_service_endpoint = var.disable_public_endpoint
  wait_till         = "IngressReady"

  zones {
    name      = local.vpc_subnets[0].zone
    subnet_id = local.vpc_subnets[0].id
  }
}

resource ibm_container_vpc_worker_pool cluster_pool {
  count             = !var.exists ? local.vpc_subnet_count - 1 : 0

  cluster           = ibm_container_vpc_cluster.cluster[0].id
  worker_pool_name  = "${local.cluster_name}-wp-${format("%02s", count.index + 1)}"
  flavor            = var.flavor
  vpc_id            = local.vpc_id
  worker_count      = var.worker_count
  resource_group_id = data.ibm_resource_group.resource_group.id

  zones {
    name      = local.vpc_subnets[count.index + 1].zone
    subnet_id = local.vpc_subnets[count.index + 1].id
  }
}

data ibm_container_vpc_cluster config {
  depends_on = [ibm_container_vpc_cluster.cluster, null_resource.create_dirs]

  name              = local.cluster_name
  alb_type          = "public"
  resource_group_id = data.ibm_resource_group.resource_group.id
}
