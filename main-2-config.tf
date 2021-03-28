locals {
  gitops_dir   = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name   = "cloud-setup"
  chart_dir    = "${local.gitops_dir}/${local.chart_name}"
  global_config = {
    clusterType = local.cluster_type_code
    ingressSubdomain = local.ingress_hostname
    tlsSecretName = local.tls_secret
  }
  ibmcloud_config = {
    apikey = var.ibmcloud_api_key
    resource_group = var.resource_group_name
    server_url = local.server_url
    cluster_type = local.cluster_type
    cluster_name = local.cluster_name
    tls_secret_name = local.tls_secret
    ingress_subdomain = local.ingress_hostname
    region = var.region
    cluster_version = local.cluster_version
  }
  cntk_dev_guide_config = {
    name = "cntk-dev-guide"
    displayName = "Cloud-Native Toolkit"
    url = "https://cloudnativetoolkit.dev"
  }
  first_app_config = {
    name = "first-app"
    displayName = "Deploy first app"
    url = "https://cloudnativetoolkit.dev/getting-started-day-1/deploy-app/"
  }
}

resource "null_resource" "list_tmp" {
  depends_on = [null_resource.create_dirs]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "ls ${local.tmp_dir}"
  }
}

data ibm_container_cluster_config cluster {
  depends_on        = [ibm_container_vpc_cluster.cluster, null_resource.list_tmp]

  cluster_name_id   = local.cluster_name
  resource_group_id = data.ibm_resource_group.resource_group.id
  config_dir        = local.cluster_config_dir
}

resource null_resource setup_kube_config {
  depends_on = [null_resource.create_dirs]

  provisioner "local-exec" {
    command = "rm -f ${local.cluster_config} && ln -s ${data.ibm_container_cluster_config.cluster.config_file_path} ${local.cluster_config}"
  }

  provisioner "local-exec" {
    command = "cp ${regex("(.*)/config.yml", data.ibm_container_cluster_config.cluster.config_file_path)[0]}/* ${local.cluster_config_dir}"
  }
}

resource null_resource setup-chart {
  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource null_resource delete-helm-cloud-config {
  depends_on = [null_resource.setup_kube_config]

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} -l name=${local.ibmcloud_release_name} --ignore-not-found"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} -l name=cloud-setup --ignore-not-found"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} ibmcloud-apikey --ignore-not-found"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${local.config_namespace} ibmcloud-config --ignore-not-found"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} cloud-access --ignore-not-found"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${local.config_namespace} cloud-config --ignore-not-found"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }
}

resource "null_resource" "delete-consolelink" {
  depends_on = [null_resource.setup_kube_config]
  count      = local.cluster_type_code == "ocp4" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink toolkit-github --ignore-not-found"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete consolelink toolkit-registry --ignore-not-found"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }
}

resource "local_file" "cloud-values" {
  depends_on = [null_resource.setup-chart]

  content  = yamlencode({
    global = local.global_config
    cloud-setup = {
      ibmcloud = local.ibmcloud_config
      cntk-dev-guide = local.cntk_dev_guide_config
      first-app = local.first_app_config
    }
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  provisioner "local-exec" {
    command = "cat ${local_file.cloud-values.filename}"
  }
}

resource "helm_release" "cloud_setup" {
  depends_on = [null_resource.setup_kube_config, null_resource.delete-helm-cloud-config, null_resource.delete-consolelink, local_file.cloud-values]

  name              = "cloud-setup"
  chart             = local.chart_dir
  version           = "0.1.0"
  namespace         = local.config_namespace
  timeout           = 1200
  dependency_update = true
  force_update      = true
  replace           = true

  disable_openapi_validation = true
}
