terraform {
  required_version = ">= 1.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11"
    }
  }
}

# -----------------------------
# AWS Provider
# -----------------------------
provider "aws" {
  region = var.aws_region
}

# -----------------------------
# Kubernetes Provider
# -----------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# -----------------------------
# Helm Provider
# -----------------------------
provider "helm" {
  kubernetes_host                   = module.eks.cluster_endpoint
  kubernetes_cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  kubernetes_token                  = data.aws_eks_cluster_auth.this.token
}
