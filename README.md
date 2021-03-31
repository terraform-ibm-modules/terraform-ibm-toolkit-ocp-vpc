# IBM Cloud OpenShift VPC cluster

Provisions an IBM Cloud OpenShift VPC cluster using a provided VPC instance and COS
instance.

## Software dependencies

The module depends on the following software components:

### Command-line tools

- terraform - v13
- kubectl

### Terraform providers

- IBM Cloud provider >= 1.18
- Helm provider >= 1.1.1 (provided by Terraform)

## Module dependencies

This module makes use of the output from other modules:

- Object Storage - github.com/cloud-native-toolkit/terraform-ibm-object-storage.git
- VPC - github.com/cloud-native-toolkit/terraform-ibm-vpc.git

## Example usage

```hcl-terraform
module "cluster" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-ocp-vpn.git?ref=v1.0.0"

  resource_group_name = var.resource_group_name
  region              = var.region
  ibmcloud_api_key    = var.ibmcloud_api_key
  name                = var.cluster_name
  worker_count        = var.worker_count
  ocp_version         = var.ocp_version
  exists              = var.cluster_exists
  name_prefix         = var.name_prefix
  vpc_name            = module.vpc.name
  vpc_subnet_count    = module.vpc.subnet_count
  cos_id              = module.cos.id
}
```

