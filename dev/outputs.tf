output "apigw_domains" { value = module.apigw.regional_domain_names }
output "auth_cnames" {
  value = {
    "auth-ext"  = module.cognito.external_auth_cname
    "auth-corp" = module.cognito.corp_auth_cname
  }
}