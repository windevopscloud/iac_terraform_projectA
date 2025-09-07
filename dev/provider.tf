terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
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
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# -----------------------------
# Helm Provider
# -----------------------------
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this_endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}