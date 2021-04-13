provider "ibm" {
  region           = var.region
  generation       = 2
  ibmcloud_api_key = var.ibmcloud_api_key
}

provider "helm" {
  version = ">= 1.1.1"

  kubernetes {
    config_path = local.cluster_config
  }
}
