# Include all modules

module "eks" {
  source = "./eks" # Should point to actual module path or repo url

  eks_cluster_name     = "${var.environment}-eks-cluster"
  eks_version          = var.eks_version
  eks_addon_coredns    = var.eks_addon_coredns
  eks_addon_kube_proxy = var.eks_addon_kube_proxy
  eks_addon_vpc_cni    = var.eks_addon_vpc_cni
  #vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  #private_subnets = data.terraform_remote_state.network.outputs.private_subnets
  lt_desired_size   = var.lt_desired_size
  lt_max_size       = var.lt_max_size
  lt_min_size       = var.lt_min_size
  lt_instance_types = var.lt_instance_types
  lt_disk_size      = var.lt_disk_size

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}