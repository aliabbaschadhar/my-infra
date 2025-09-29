# TODO:  provider "digitalocean" {
#   token = var.digitalocean_token
# }
# I don't think so we need to add here 

resource "digitalocean_vpc" "main" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = "10.0.0.0/16"
}

resource "digitalocean_kubernetes_cluster" "primary" {
  name     = var.cluster_name
  region   = var.region
  version  = "1.28.2-do.0"
  vpc_uuid = digitalocean_vpc.main.id

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    auto_scale = true
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
  }

}
