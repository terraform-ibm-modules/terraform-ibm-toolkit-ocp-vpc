module "vpc" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc.git"

  resource_group_name = var.resource_group_name
  region              = var.region
  name_prefix         = var.name_prefix
  ibmcloud_api_key    = var.ibmcloud_api_key
  subnet_count        = var.subnet_count
  public_gateway      = var.vpc_public_gateway == "true"
}
