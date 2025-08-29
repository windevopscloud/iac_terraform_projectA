data "terraform_remote_state" "bootstrap" {
  backend = "s3"

  config = {
    bucket = "windevopscloud-terraform-s3"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_vpc" "selected" {
  id = data.terraform_remote_state.bootstrap.outputs.vpc_vpc_id
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_availability_zones" "available" {}

data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"] # This is crucial

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks_version}-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}