output "id" {
  value       = data.ibm_container_vpc_cluster.config.id
  description = "ID of the cluster."
}

output "name" {
  value       = local.cluster_name
  description = "Name of the cluster."
}

output "resource_group_name" {
  value       = var.resource_group_name
  description = "Name of the resource group containing the cluster."
  depends_on  = [data.ibm_container_cluster_config.cluster]
}

output "region" {
  value       = var.region
  description = "Region containing the cluster."
  depends_on  = [data.ibm_container_cluster_config.cluster]
}

output "config_file_path" {
  value       = local.cluster_config
  description = "Path to the config file for the cluster."
  depends_on  = [data.ibm_container_cluster_config.cluster]
}

output "platform" {
  value = {
    id         = data.ibm_container_vpc_cluster.config.id
    kubeconfig = local.cluster_config
    server_url = local.server_url
    type       = local.cluster_type
    type_code  = local.cluster_type_code
    version    = local.cluster_version
    ingress    = local.ingress_hostname
    tls_secret = local.tls_secret
  }
  sensitive = true
  description = "Configuration values for the cluster platform"
  depends_on  = [data.ibm_container_cluster_config.cluster]
}

output "sync" {
  value = local.cluster_name
  description = "Value used to sync downstream modules"
  depends_on  = [data.ibm_container_cluster_config.cluster]
}

output "total_worker_count" {
  description = "The total number of workers for the cluster. (subnets * number of workers)"
  value = local.total_workers
  depends_on  = [data.ibm_container_vpc_cluster_worker.workers]
}

output "workers" {
  description = "List of objects containing data for all workers "
  value = local.workers
  depends_on  = [data.ibm_container_vpc_cluster_worker.workers]
}

output "server_url" {
  description = "The url used to connect to the api server. If the cluster has public endpoints enabled this will be the public api server, otherwise this will be the private api server url"
  value = data.ibm_container_vpc_cluster.config.public_service_endpoint ? data.ibm_container_vpc_cluster.config.public_service_endpoint_url : data.ibm_container_vpc_cluster.config.private_service_endpoint_url
}

output "username" {
  description = "The username of the admin user for the cluster"
  value = "apikey"
}

output "password" {
  description = "The password of the admin user for the cluster"
  value = var.ibmcloud_api_key
  sensitive = true
}

output "token" {
  description = "The admin user token used to generate the cluster"
  value = ""
  sensitive = true
}
