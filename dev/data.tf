data "terraform_remote_state" "bootstrap" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "bootstrap/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  vpc_id          = data.terraform_remote_state.bootstrap.outputs.vpc_id
  private_subnets = data.terraform_remote_state.bootstrap.outputs.private_subnets
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}