module "vpc" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-vpc"

  resource_group_name = module.resource_group.name
  region              = var.region
  name_prefix         = var.name_prefix
  common_tags = var.common_tags
  tags = ["vpc"]
}
