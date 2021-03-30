module "cos" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-object-storage"

  provision = true
  resource_group_name = var.resource_group_name
  name_prefix = var.name_prefix
}
