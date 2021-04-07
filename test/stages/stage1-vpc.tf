module "vpc" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc.git"

  resource_group_name = module.resource_group.name
  region              = var.region
  name_prefix         = var.name_prefix
  ibmcloud_api_key    = var.ibmcloud_api_key
  subnet_count        = var.vpc_subnet_count
  subnets             = jsondecode(var.vpc_subnets)
  public_gateway      = var.vpc_public_gateway == "true"
}
