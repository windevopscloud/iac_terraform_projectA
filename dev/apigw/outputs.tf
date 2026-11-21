output "regional_domain_names" {
  value = { for k, d in aws_api_gateway_domain_name.this : d.domain_name => d.regional_domain_name }
}