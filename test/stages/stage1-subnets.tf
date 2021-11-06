module "subnets" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-subnets.git"

  resource_group_id = module.resource_group.id
  region            = var.region
  vpc_name          = module.vpc.name
  gateways          = module.gateways.gateways
  _count            = 2
  label             = "bastion"
}
