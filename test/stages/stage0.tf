terraform {
  required_version = ">= 0.13.0"

  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

locals {
  name_prefix_test = "${var.name_prefix}-${random_string.this.result}"
}

resource "random_string" "this" {
  length = 6
  special = false
  upper = false
}
