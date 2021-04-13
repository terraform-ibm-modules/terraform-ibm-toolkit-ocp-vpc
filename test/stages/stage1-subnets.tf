module "subnets" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-subnets.git"

  resource_group_id = module.resource_group.id
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  vpc_name          = module.vpc.name
  acl_id            = module.vpc.acl_id
  gateways          = module.gateways.gateways
  _count            = 2
  label             = "bastion"
}
