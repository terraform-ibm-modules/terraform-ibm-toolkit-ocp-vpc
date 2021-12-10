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
  depends_on  = [data.ibm_container_vpc_cluster.config]
}

output "region" {
  value       = var.region
  description = "Region containing the cluster."
  depends_on  = [data.ibm_container_vpc_cluster.config]
}

output "config_file_path" {
  value       = local.cluster_config
  description = "Path to the config file for the cluster."
  depends_on  = [data.ibm_container_vpc_cluster.config]
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
  depends_on  = [data.ibm_container_vpc_cluster.config]
}

output "sync" {
  value = local.cluster_name
  description = "Value used to sync downstream modules"
  depends_on  = [data.ibm_container_vpc_cluster.config]
}

output "total_worker_count" {
  description = "The total number of workers for the cluster. (subnets * number of workers)"
  value = local.total_workers
  depends_on  = [ibm_container_vpc_worker_pool.cluster_pool]
}

output "workers" {
  description = "List of objects containing data for all workers "
  value = local.workers
  depends_on  = [ibm_container_vpc_worker_pool.cluster_pool]
}
