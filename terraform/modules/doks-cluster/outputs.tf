output "cluster_id" {
  value = digitalocean_kubernetes_cluster.primary.id
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.primary.name
}

output "kube_config" {
  value     = digitalocean_kubernetes_cluster.primary.kube_config[0].raw_config
  sensitive = true
}

output "cluster_endpoint" {
  value = digitalocean_kubernetes_cluster.primary.endpoint
}

output "vpc_uuid" {
  value = digitalocean_vpc.main.id
}
