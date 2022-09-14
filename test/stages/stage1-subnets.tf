module "subnets" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-vpc-subnets"

  resource_group_name = module.resource_group.name
  region            = var.region
  vpc_name          = module.vpc.name
  gateways          = module.gateways.gateways
  _count            = 2
  label             = "bastion"
  common_tags = var.common_tags
  tags = ["subnet"]
}
