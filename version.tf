terraform {
  required_version = ">= 0.13.0"

  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      version = ">= 1.18"
    }
    clis = {
      source = "cloud-native-toolkit/clis"
    }
  }
}
