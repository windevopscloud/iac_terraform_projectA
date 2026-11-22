state_bucket_name           = "windevopscloud-terraform-bucket"
state_table_name            = "windevopscloud-terraform-lock"
aws_region                  = "us-east-1"
environment                 = "poc"
eks_cluster_name            = "eks-cluster"
eks_version                 = "1.35"
eks_addon_coredns           = "v1.14.7-eksbuild.22"
eks_addon_kube_proxy        = "v1.35.3-eksbuild.62"
eks_addon_vpc_cni           = "v1.22.4-eksbuild.14"
eks_addon_ebs_csi_driver    = "v1.60.1-eksbuild.1"
lt_desired_size             = 2
lt_max_size                 = 4
lt_min_size                 = 1
lt_instance_types           = ["m5.large"]
lt_disk_size                = 20
lt_key_name                 = null
eks_tools_instance_type     = "m5.large"
db_name                     = "signuprds"
db_username                 = "signuprdsmaster"
db_engine_version           = "17"
db_instance_class           = "db.t4g.small"
db_allocated_storage        = 20
db_multi_az                 = false
db_backup_retention_days    = 7
eks_addon_secrets_store_csi = "v3.1.1-eksbuild.1"
app_namespace               = "default"
app_service_account         = "signup-app"
istio_version               = "1.31.4"

cognito_external_scopes = ["extsvc1.invoke", "extsvc2.invoke", "outsvc1.invoke",
"outsvc2.invoke"]

cognito_external_clients = {
  consumer-a = ["extsvc1.invoke", "extsvc2.invoke"]
  intsvc1    = ["outsvc1.invoke"]
  intsvc2    = ["outsvc2.invoke"]
}

cognito_corp_scopes = ["corpsvc1.invoke", "corpsvc2.invoke"]

cognito_corp_clients = {
  corp-app-a = ["corpsvc1.invoke", "corpsvc2.invoke"]
}

cognito_external_callback_urls = ["https://extsvc.windevopscloud.com/success/extsvc-list/"]
cognito_external_logout_urls   = ["https://extsvc.windevopscloud.com/"]
cognito_corp_callback_urls     = ["https://corpsvc.windevopscloud.com/success/corpsvc-list/"]
cognito_corp_logout_urls       = ["https://corpsvc.windevopscloud.com/"]
cognito_external_web_scopes    = ["extsvc1.invoke", "extsvc2.invoke"]
cognito_corp_web_scopes        = ["corpsvc1.invoke", "corpsvc2.invoke"]
cognito_external_test_users    = ["ext-user1"]
cognito_corp_test_users        = ["corp-user1"]
cognito_external_auth_domain   = "auth-ext.windevopscloud.com"
cognito_corp_auth_domain       = "auth-corp.windevopscloud.com"