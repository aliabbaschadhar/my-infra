# Backend and provider configuration
terraform {
  backend "s3" {
    bucket = "my-infra"
    key    = "production/terraform.tfstate"
    region = "auto"

    endpoints                   = { s3 = "https://f68badd75cec05f1f420e42be2c24b70.r2.cloudflarestorage.com" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    # Why: Installs Vault, External Secrets Operator, and other Helm charts via Terraform What it does: helm_release resources (instead of manual helm install)
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3"
    }

    # DigitalOcean → Creates cluster
    # Kubernetes → Creates namespaces in that cluster
    # Helm → Installs Vault and External Secrets Operator
    # Cloudflare → Points your domain to the cluster
  }

}


provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "kubernetes" {
  host  = module.doks_cluster.cluster_endpoint
  token = module.doks_cluster.cluster_token
  cluster_ca_certificate = base64decode(
    yamldecode(module.doks_cluster.kube_config).clusters[0].cluster["certificate-authority-data"]
  )
}

provider "helm" {
  kubernetes = {
    host  = module.doks_cluster.cluster_endpoint
    token = module.doks_cluster.cluster_token
    cluster_ca_certificate = base64decode(
      yamldecode(module.doks_cluster.kube_config).clusters[0].cluster["certificate-authority-data"]
    )
  }
}


module "doks_cluster" {
  source       = "../../modules/doks-cluster"
  cluster_name = var.cluster_name
  region       = var.region
  node_size    = var.node_size
  min_nodes    = var.min_nodes
  max_nodes    = var.max_nodes
}

# Create namespace to avoid running commands
resource "kubernetes_namespace" "shared" {
  metadata {
    name = "shared"
  }
  depends_on = [module.doks_cluster]
}

resource "kubernetes_namespace" "novahost" {
  metadata {
    name = "novahost"
  }

  depends_on = [module.doks_cluster]
}

resource "kubernetes_namespace" "excalidraw" {
  metadata {
    name = "excalidraw"
  }

  depends_on = [module.doks_cluster]
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [module.doks_cluster]
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }

  depends_on = [module.doks_cluster]
}
