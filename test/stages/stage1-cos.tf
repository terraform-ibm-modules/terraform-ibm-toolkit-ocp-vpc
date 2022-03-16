module "cos" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-object-storage"

  provision = true
  resource_group_name = module.resource_group.name
  name_prefix = local.name_prefix_test
}
