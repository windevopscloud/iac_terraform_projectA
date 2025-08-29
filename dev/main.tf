# Include all modules

module "eks" {
  source = "./eks" # Should point to actual module path

  cluster_name = "${var.environment}-eks-cluster"
  eks_version  = var.eks_version
  #vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  #private_subnets = data.terraform_remote_state.network.outputs.private_subnets
  desired_size   = var.desired_size
  max_size       = var.max_size
  min_size       = var.min_size
  instance_types = var.instance_types
  disk_size      = var.disk_size

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}
