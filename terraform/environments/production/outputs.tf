output "cluster_id" {
  value       = module.doks_cluster.cluster_id
  description = "ID of the DOKS cluster"
}

output "cluster_name" {
  value       = module.doks_cluster.cluster_name
  description = "Name of the DOKS cluster"
}

output "cluster_endpoint" {
  value       = module.doks_cluster.cluster_endpoint
  description = "Endpoint of the DOKS cluster"
}

output "kube_config" {
  description = "Kubernetes config for cluster access"
  value       = module.doks_cluster.kube_config
  sensitive   = true
}

output "vpc_uuid" {
  value       = module.doks_cluster.vpc_uuid
  description = "UUID of the VPC associated with the DOKS cluster"
}
