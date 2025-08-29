# Include all modules
module "github_runner" {
  source = "./github-runner"
  
  create_github_runner    = var.create_github_runner
  labels = var.labels
  runner_instance_type    = var.runner_instance_type
  github_organization     = var.github_organization
  github_repository       = var.github_repository
  terraform_version       = var.terraform_version
  helm_version            = var.helm_version
  kubectl_version         = var.kubectl_version
  node_version            = var.node_version
  runner_version          = var.runner_version
  environment             = var.environment
}

module "eks_cluster" {
  source = "./eks"
  
  environment     = var.environment
  aws_region      = var.aws_region
  cluster_version = var.cluster_version
  desired_size    = var.desired_size
  max_size        = var.max_size
  min_size        = var.min_size
  instance_types  = var.instance_types
  disk_size       = var.disk_size
}