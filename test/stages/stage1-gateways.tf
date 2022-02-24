module "gateways" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-gateways.git"

  resource_group_id = module.resource_group.id
  region            = var.region
  vpc_name          = module.vpc.name
}
