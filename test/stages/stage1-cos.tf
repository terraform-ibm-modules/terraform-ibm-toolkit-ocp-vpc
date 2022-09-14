module "cos" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-object-storage"

  provision = true
  resource_group_name = module.resource_group.name
  name_prefix = var.name_prefix
  common_tags = var.common_tags
  tags = ["cos"]
}
