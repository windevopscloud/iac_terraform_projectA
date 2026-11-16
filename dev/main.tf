# Include all modules

module "eks" {
  source = "./eks" # Should point to actual module path or repo url

  environment              = var.environment
  aws_region               = var.aws_region
  state_bucket_name        = var.state_bucket_name
  eks_cluster_name         = "${var.environment}-eks-cluster"
  eks_version              = var.eks_version
  eks_addon_coredns        = var.eks_addon_coredns
  eks_addon_kube_proxy     = var.eks_addon_kube_proxy
  eks_addon_vpc_cni        = var.eks_addon_vpc_cni
  eks_addon_ebs_csi_driver = var.eks_addon_ebs_csi_driver
  vpc_id                   = local.vpc_id
  private_subnets          = local.private_subnets
  lt_desired_size          = var.lt_desired_size
  lt_max_size              = var.lt_max_size
  lt_min_size              = var.lt_min_size
  lt_instance_types        = var.lt_instance_types
  lt_disk_size             = var.lt_disk_size
  lt_key_name              = var.lt_key_name
  eks_tools_instance_type  = var.eks_tools_instance_type

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

module "ecr" {
  source = "./ecr" # Should point to actual module path or repo url

  environment      = var.environment
  aws_region       = var.aws_region
  eks_cluster_name = "${var.environment}-eks-cluster"
  ecr_repos        = var.ecr_repos

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  # Ensure EKS Cluster and relevant resources are created first
  depends_on = [module.eks]
}

module "rds" {
  source = "./rds" # Should point to actual module path or repo url

  environment              = var.environment
  node_security_group_id   = module.eks.node_security_group_id
  db_name                  = var.db_name
  db_username              = var.db_username
  db_engine_version        = var.db_engine_version
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_multi_az              = var.db_multi_az
  db_backup_retention_days = var.db_backup_retention_days

  tags = { Environment = var.environment, Terraform = "true" }
}