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
}

variable "flavor" {
  type        = string
  description = "The machine type that will be provisioned for classic infrastructure"
  default     = "bx2.4x16"
}

variable "ocp_version" {
  type        = string
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x)"
  default     = "4.8"
}

variable "exists" {
  type        = bool
  description = "Flag indicating if the cluster already exists (true or false)"
  default     = false
}

variable "disable_public_endpoint" {
  type        = bool
  description = "Flag indicating that the public endpoint should be disabled"
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

variable "force_delete_storage" {
  type        = bool
  description = "Attribute to force the removal of persistent storage associtated with the cluster"
  default     = false
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags that should be added to the instance"
}

# VPC Variables
variable "vpc_name" {
  type        = string
  description = "Name of the VPC instance that will be used"
}

variable "vpc_subnet_count" {
  type        = number
  description = "Number of vpc subnets"
}

variable "vpc_subnets" {
  type        = list(object({
    label = string
    id    = string
    zone  = string
  }))
  description = "List of subnets with labels"
}

# COS Variables
variable "cos_id" {
  type        = string
  description = "The crn of the COS instance that will be used with the OCP instance"
}

variable "kms_enabled" {
  type        = bool
  description = "Flag indicating that kms encryption should be enabled for this cluster"
  default     = false
}

variable "kms_id" {
  type        = string
  description = "The crn of the KMS instance that will be used to encrypt the cluster."
  default     = null
}

variable "kms_key_id" {
  type        = string
  description = "The id of the root key in the KMS instance that will be used to encrypt the cluster."
  default     = null
}

variable "kms_private_endpoint" {
  type        = bool
  description = "Flag indicating that the private endpoint should be used to connect the KMS system to the cluster."
  default     = true
}

variable "login" {
  type        = bool
  description = "Flag indicating that after the cluster is provisioned, the module should log into the cluster"
  default     = false
}

variable "sync" {
  type        = string
  description = "Value used to order dependencies"
  default     = ""
}
