terraform {
  required_version = ">= 0.15.0"

  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
    }
    clis = {
      source = "cloud-native-toolkit/clis"
    }
  }
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  bin_dir = "${path.cwd}/test_bin_dir"
  clis = ["jq", "oc"]
}

resource local_file bin_dir {
  filename = "${path.cwd}/.bin_dir"

  content = module.setup_clis.bin_dir
}
