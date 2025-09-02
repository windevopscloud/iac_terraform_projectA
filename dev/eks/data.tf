data "terraform_remote_state" "bootstrap" {
  backend = "s3"

  config = {
    bucket = "windevopscloud-terraform-bucket"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

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
    values = ["private-*-poc"]
  }
}

data "aws_route_tables" "private" {
  vpc_id = data.aws_vpc.selected.id
  filter {
    name   = "tag:Name"
    values = ["private-rt-*-poc"]
  }
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_availability_zones" "available" {}

data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.eks_version}/amazon-linux-2/recommended/image_id"
}
