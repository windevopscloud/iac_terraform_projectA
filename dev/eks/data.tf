data "terraform_remote_state" "bootstrap" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "bootstrap/terraform.tfstate"
    region = var.aws_region
  }
}

# VPC, Subnet, RT, SG information from bootstrap terraform state
#data "aws_vpc" "selected" {
#  id = data.terraform_remote_state.bootstrap.outputs.vpc_id
#}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["private-*"]
  }
}

data "aws_subnet" "private_for_sg" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_route_tables" "private" {
  vpc_id = data.aws_vpc.selected.id
  filter {
    name   = "tag:Name"
    values = ["private-rt-*"]
  }
}

data "aws_security_group" "github_runner" {
  filter {
    name   = "tag:Name"
    values = ["github-runner-sg"]
  }
}

data "aws_security_group" "vpc_endpoint_ssm" {
  filter {
    name   = "tag:Name"
    values = ["vpc-endpoint-sg-ssm"]
  }
}

# EKS Cluster information from AWS
data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

# Commenting the tls certifcate as the DNS resolution not working in us-east-1
#data "tls_certificate" "eks" {
#  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
#}

# Get the existing aws-auth configmap
data "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  depends_on = [aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}

# Optimised AMI for EKS node groups EC2
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.eks_version}/amazon-linux-2/recommended/image_id"
}

# Custom AMI for EKS Tools EC2
data "aws_ami" "eks_tools" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["eks-tools-ami-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
