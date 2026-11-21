data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

########################################
# External pool: third parties and the services that call extsvc
########################################
resource "aws_cognito_user_pool" "external" {
  name = "ext-api-${var.environment}"
  tags = var.tags

  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_resource_server" "external" {
  identifier   = "ext-api"
  name         = "ext-api"
  user_pool_id = aws_cognito_user_pool.external.id

  dynamic "scope" {
    for_each = var.external_scopes
    content {
      scope_name        = scope.value
      scope_description = "Call ${split(".", scope.value)[0]}"
    }
  }
}

resource "aws_cognito_user_pool_domain" "external" {
  domain       = "ext-api-${var.environment}-${local.account_id}"
  user_pool_id = aws_cognito_user_pool.external.id
}

resource "aws_cognito_user_pool_client" "external" {
  for_each = var.external_clients

  name         = each.key
  user_pool_id = aws_cognito_user_pool.external.id

  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes                 = [for s in each.value : "${aws_cognito_resource_server.external.identifier}/${s}"]

  access_token_validity = 60
  token_validity_units {
    access_token = "minutes"
  }

  depends_on = [aws_cognito_resource_server.external]
}

########################################
# Corporate pool: corporate apps (federated users are added in a later step)
########################################
resource "aws_cognito_user_pool" "corp" {
  name = "corp-api-${var.environment}"
  tags = var.tags

  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_resource_server" "corp" {
  identifier   = "corp-api"
  name         = "corp-api"
  user_pool_id = aws_cognito_user_pool.corp.id

  dynamic "scope" {
    for_each = var.corp_scopes
    content {
      scope_name        = scope.value
      scope_description = "Call ${split(".", scope.value)[0]}"
    }
  }
}

resource "aws_cognito_user_pool_domain" "corp" {
  domain       = "corp-api-${var.environment}-${local.account_id}"
  user_pool_id = aws_cognito_user_pool.corp.id
}

resource "aws_cognito_user_pool_client" "corp" {
  for_each = var.corp_clients

  name         = each.key
  user_pool_id = aws_cognito_user_pool.corp.id

  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes                 = [for s in each.value : "${aws_cognito_resource_server.corp.identifier}/${s}"]

  access_token_validity = 60
  token_validity_units {
    access_token = "minutes"
  }

  depends_on = [aws_cognito_resource_server.corp]
}

########################################
# Client IDs and secrets go to Secrets Manager (the sandbox is rebuilt, so they change each time)
########################################
resource "aws_secretsmanager_secret" "external_clients" {
  name                    = "cognito/${var.environment}/external-clients"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "external_clients" {
  secret_id = aws_secretsmanager_secret.external_clients.id
  secret_string = jsonencode({
    for name, c in aws_cognito_user_pool_client.external :
    name => { client_id = c.id, client_secret = c.client_secret }
  })
}

resource "aws_secretsmanager_secret" "corp_clients" {
  name                    = "cognito/${var.environment}/corp-clients"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "corp_clients" {
  secret_id = aws_secretsmanager_secret.corp_clients.id
  secret_string = jsonencode({
    for name, c in aws_cognito_user_pool_client.corp :
    name => { client_id = c.id, client_secret = c.client_secret }
  })
}

########################################
# Browser clients (public, code + PKCE)
########################################
resource "aws_cognito_user_pool_client" "external_web" {
  name         = "web-ext"
  user_pool_id = aws_cognito_user_pool.external.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = concat(["openid"], [for s in var.external_web_scopes : "${aws_cognito_resource_server.external.identifier}/${s}"])
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = var.external_callback_urls
  logout_urls                          = var.external_logout_urls
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors        = "ENABLED"

  access_token_validity = 60
  id_token_validity     = 60
  token_validity_units {
    access_token = "minutes"
    id_token     = "minutes"
  }

  depends_on = [aws_cognito_resource_server.external]
}

resource "aws_cognito_user_pool_client" "corp_web" {
  name         = "web-corp"
  user_pool_id = aws_cognito_user_pool.corp.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = concat(["openid"], [for s in var.corp_web_scopes : "${aws_cognito_resource_server.corp.identifier}/${s}"])
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = var.corp_callback_urls
  logout_urls                          = var.corp_logout_urls
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors        = "ENABLED"

  access_token_validity = 60
  id_token_validity     = 60
  token_validity_units {
    access_token = "minutes"
    id_token     = "minutes"
  }

  depends_on = [aws_cognito_resource_server.corp]
}

########################################
# Test users (passwords are random and saved in Secrets Manager)
########################################
resource "random_password" "external_user" {
  for_each         = toset(var.external_test_users)
  length           = 16
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#$%"
}

resource "random_password" "corp_user" {
  for_each         = toset(var.corp_test_users)
  length           = 16
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#$%"
}

resource "aws_cognito_user" "external" {
  for_each       = toset(var.external_test_users)
  user_pool_id   = aws_cognito_user_pool.external.id
  username       = each.key
  password       = random_password.external_user[each.key].result
  message_action = "SUPPRESS"
}

resource "aws_cognito_user" "corp" {
  for_each       = toset(var.corp_test_users)
  user_pool_id   = aws_cognito_user_pool.corp.id
  username       = each.key
  password       = random_password.corp_user[each.key].result
  message_action = "SUPPRESS"
}

resource "aws_secretsmanager_secret" "test_users" {
  name                    = "cognito/${var.environment}/test-users"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "test_users" {
  secret_id = aws_secretsmanager_secret.test_users.id
  secret_string = jsonencode({
    external = { for u in var.external_test_users : u => random_password.external_user[u].result }
    corp     = { for u in var.corp_test_users : u => random_password.corp_user[u].result }
  })
}