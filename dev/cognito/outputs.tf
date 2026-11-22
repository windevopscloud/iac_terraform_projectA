output "external_user_pool_arn" { value = aws_cognito_user_pool.external.arn }
output "external_user_pool_id" { value = aws_cognito_user_pool.external.id }
output "external_issuer" { value = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.external.id}" }
#output "external_token_endpoint" { value = "https://${aws_cognito_user_pool_domain.external.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token" }
output "external_token_endpoint" { value = "https://${var.external_auth_domain}/oauth2/token" }
output "external_clients_secret_arn" { value = aws_secretsmanager_secret.external_clients.arn }

output "corp_user_pool_arn" { value = aws_cognito_user_pool.corp.arn }
output "corp_user_pool_id" { value = aws_cognito_user_pool.corp.id }
output "corp_issuer" { value = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.corp.id}" }
#output "corp_token_endpoint" { value = "https://${aws_cognito_user_pool_domain.corp.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token" }
output "corp_token_endpoint" { value = "https://${var.corp_auth_domain}/oauth2/token" }
output "corp_clients_secret_arn" { value = aws_secretsmanager_secret.corp_clients.arn }

output "external_web_client_id" { value = aws_cognito_user_pool_client.external_web.id }
output "corp_web_client_id" { value = aws_cognito_user_pool_client.corp_web.id }
output "test_users_secret_arn" { value = aws_secretsmanager_secret.test_users.arn }

output "external_auth_cname" { value = aws_cognito_user_pool_domain.external.cloudfront_distribution }
output "corp_auth_cname" { value = aws_cognito_user_pool_domain.corp.cloudfront_distribution }