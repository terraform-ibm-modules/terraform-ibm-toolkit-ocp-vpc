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
  depends_on  = [null_resource.wait_for_iam_sync]
}

output "region" {
  value       = var.region
  description = "Region containing the cluster."
  depends_on  = [null_resource.wait_for_iam_sync]
}

output "config_file_path" {
  value       = local.cluster_config
  description = "Path to the config file for the cluster."
  depends_on  = [null_resource.wait_for_iam_sync]
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
  depends_on  = [null_resource.wait_for_iam_sync]
}

output "sync" {
  value = local.cluster_name
  description = "Value used to sync downstream modules"
  depends_on  = [null_resource.wait_for_iam_sync]
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
  value = data.external.credentials.result.server_url
}

output "username" {
  description = "The username of the admin user for the cluster"
  value = data.external.credentials.result.username
}

output "password" {
  description = "The password of the admin user for the cluster"
  value = data.external.credentials.result.password
  sensitive = true
}

output "token" {
  description = "The admin user token used to generate the cluster"
  value = data.external.credentials.result.token
  sensitive = true
}
