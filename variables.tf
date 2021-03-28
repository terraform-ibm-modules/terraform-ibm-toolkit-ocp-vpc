# Resource Group Variables
variable "resource_group_name" {
  type        = string
  description = "The name of the IBM Cloud resource group where the cluster will be created/can be found."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
}

# Cluster Variables
variable "name" {
  type        = string
  description = "The name of the cluster that will be created within the resource group"
  default     = ""
}

variable "worker_count" {
  type        = number
  description = "The number of worker nodes that should be provisioned for classic infrastructure"
  default     = 3

  validation {
    condition = (
      var.worker_count >= 2
    )
    error_message = "The minimum number of workers for an OCP cluster is 2"
  }
}

variable "flavor" {
  type        = string
  description = "The machine type that will be provisioned for classic infrastructure"
  default     = "bx2.4x16"
}

variable "ocp_version" {
  type        = string
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x)"
  default     = "4.6"

  validation {
    condition = (
      regex("^4[.]", var.ocp_version) == "4."
    )
    error_message = "The ocp_version must be formatted as 4.x."
  }
}

variable "exists" {
  type        = bool
  description = "Flag indicating if the cluster already exists (true or false)"
  default     = false
}

variable "name_prefix" {
  type        = string
  description = "The prefix name for the service. If not provided it will default to the resource group name"
  default     = ""
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = "cloud_pak"
}

variable "cos_name" {
  type        = string
  description = "(optional) The name of the cos instance that will be used for the OCP 4 vpc instance"
  default     = ""
}

variable "provision_cos" {
  type        = bool
  description = "Flag indicating that the cos instance should be provisioned, if necessary"
  default     = true
}

variable "gitops_dir" {
  type        = string
  description = "Directory where the gitops repo content should be written"
  default     = ""
}

# VPC Variables
variable "vpc_name" {
  type        = string
  description = "Name of the VPC instance that will be used"
}

variable "vpc_subnet_count" {
  type        = number
  description = "Number of vpc zones"
}
