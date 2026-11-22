# Include all modules

module "eks" {
  source = "./eks" # Should point to actual module path or repo url

  environment                 = var.environment
  aws_region                  = var.aws_region
  state_bucket_name           = var.state_bucket_name
  eks_cluster_name            = var.eks_cluster_name
  eks_version                 = var.eks_version
  eks_addon_coredns           = var.eks_addon_coredns
  eks_addon_kube_proxy        = var.eks_addon_kube_proxy
  eks_addon_vpc_cni           = var.eks_addon_vpc_cni
  eks_addon_ebs_csi_driver    = var.eks_addon_ebs_csi_driver
  eks_addon_secrets_store_csi = var.eks_addon_secrets_store_csi
  vpc_id                      = local.vpc_id
  private_subnets             = local.private_subnets
  lt_desired_size             = var.lt_desired_size
  lt_max_size                 = var.lt_max_size
  lt_min_size                 = var.lt_min_size
  lt_instance_types           = var.lt_instance_types
  lt_disk_size                = var.lt_disk_size
  lt_key_name                 = var.lt_key_name
  eks_tools_instance_type     = var.eks_tools_instance_type

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

module "ecr" {
  source = "./ecr" # Should point to actual module path or repo url

  environment      = var.environment
  aws_region       = var.aws_region
  eks_cluster_name = var.eks_cluster_name
  ecr_repos        = local.ecr_repos

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
  tools_security_group_id  = module.eks.tools_security_group_id

  tags = { Environment = var.environment, Terraform = "true" }
}

module "ses" {
  source = "./ses"

  environment            = var.environment
  node_security_group_id = module.eks.node_security_group_id

  tags = { Environment = var.environment, Terraform = "true" }
}

module "secrets" {
  source = "./secrets"

  environment               = var.environment
  aws_region                = var.aws_region
  oidc_provider_arn         = module.eks.oidc_provider_arn
  oidc_provider_url         = module.eks.oidc_provider_url
  service_account_namespace = var.app_namespace
  service_account_name      = var.app_service_account
  secret_arns = [
    module.rds.db_secret_arn,
    module.ses.smtp_secret_arn,
  ]

  tags = { Environment = var.environment, Terraform = "true" }
}

module "s3" {
  source              = "./s3"
  environment         = var.environment
  aws_region          = var.aws_region
  eks_tools_role_name = module.eks.tools_role_name
}

module "lbcontroller" {
  source = "./lbcontroller"

  environment       = var.environment
  aws_region        = var.aws_region
  cluster_name      = var.eks_cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  tags = { Environment = var.environment, Terraform = "true" }
}

module "cognito" {
  source = "./cognito"

  environment            = var.environment
  aws_region             = var.aws_region
  external_scopes        = var.cognito_external_scopes
  external_clients       = var.cognito_external_clients
  corp_scopes            = var.cognito_corp_scopes
  corp_clients           = var.cognito_corp_clients
  external_callback_urls = var.cognito_external_callback_urls
  external_logout_urls   = var.cognito_external_logout_urls
  corp_callback_urls     = var.cognito_corp_callback_urls
  corp_logout_urls       = var.cognito_corp_logout_urls
  external_web_scopes    = var.cognito_external_web_scopes
  corp_web_scopes        = var.cognito_corp_web_scopes
  external_test_users    = var.cognito_external_test_users
  corp_test_users        = var.cognito_corp_test_users

  tags = { Environment = var.environment, Terraform = "true" }
}

module "istio" {
  source = "./istio"

  aws_region        = var.aws_region
  istio_version     = var.istio_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  depends_on = [module.lbcontroller]
}

module "istio_ingress" {
  source                 = "./istio_ingress"
  environment            = var.environment
  istio_version          = var.istio_version
  private_subnet_ids     = local.private_subnets
  node_security_group_id = module.eks.node_security_group_id
  istiod_id              = module.istio.istiod_id
}

module "apigw" {
  source                 = "./apigw"
  environment            = var.environment
  external_user_pool_arn = module.cognito.external_user_pool_arn
  corp_user_pool_arn     = module.cognito.corp_user_pool_arn
  depends_on             = [module.istio_ingress]
}

module "istio_egress" {
  source                 = "./istio_egress"
  istio_version          = var.istio_version
  istiod_id              = module.istio.istiod_id
  node_security_group_id = module.eks.node_security_group_id
}