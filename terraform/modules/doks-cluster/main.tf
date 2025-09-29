terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_vpc" "main" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = "10.0.0.0/16"
}

resource "digitalocean_kubernetes_cluster" "primary" {
  name     = var.cluster_name
  region   = var.region
  version  = "1.33.1-do.4"
  vpc_uuid = digitalocean_vpc.main.id

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    auto_scale = true
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
  }

}
