terraform {
  backend "s3" {
    bucket = "my-infra"
    key    = "production/terraform.tfstate"
    region = "auto"

    endpoint                    = "https://f68badd75cec05f1f420e42be2c24b70.r2.cloudflarestorage.com"
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
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    # Why: Installs Vault, External Secrets Operator, and other Helm charts via Terraform What it does: helm_release resources (instead of manual helm install)
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }

    # DigitalOcean → Creates cluster
    # Kubernetes → Creates namespaces in that cluster
    # Helm → Installs Vault and External Secrets Operator
    # Cloudflare → Points your domain to the cluster
  }

}
