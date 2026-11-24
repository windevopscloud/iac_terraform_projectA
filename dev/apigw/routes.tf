# Shared: /api/<svc> routes, portal root and proxy methods + integrations

# ---- /api/<svc> : Cognito protected ----
resource "aws_api_gateway_resource" "api" {
  for_each    = local.apis
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  parent_id   = aws_api_gateway_rest_api.this[each.key].root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "route" {
  for_each    = local.routes
  rest_api_id = aws_api_gateway_rest_api.this[each.value.api].id
  parent_id   = aws_api_gateway_resource.api[each.value.api].id
  path_part   = each.value.name
}

resource "aws_api_gateway_method" "route" {
  for_each             = local.routes
  rest_api_id          = aws_api_gateway_rest_api.this[each.value.api].id
  resource_id          = aws_api_gateway_resource.route[each.key].id
  http_method          = "ANY"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito[each.value.api].id
  authorization_scopes = [each.value.scope]
}

resource "aws_api_gateway_integration" "route" {
  for_each                = local.routes
  rest_api_id             = aws_api_gateway_rest_api.this[each.value.api].id
  resource_id             = aws_api_gateway_resource.route[each.key].id
  http_method             = aws_api_gateway_method.route[each.key].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "https://${local.apis[each.value.api].host}/api/${each.value.name}"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.this[each.value.api].id
  tls_config { insecure_skip_verification = true }
}

# ---- portal: / and /{proxy+}, no auth ----
resource "aws_api_gateway_method" "root" {
  for_each      = local.apis
  rest_api_id   = aws_api_gateway_rest_api.this[each.key].id
  resource_id   = aws_api_gateway_rest_api.this[each.key].root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  for_each                = local.apis
  rest_api_id             = aws_api_gateway_rest_api.this[each.key].id
  resource_id             = aws_api_gateway_rest_api.this[each.key].root_resource_id
  http_method             = aws_api_gateway_method.root[each.key].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "https://${each.value.host}/"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.this[each.key].id
  tls_config { insecure_skip_verification = true }
}

resource "aws_api_gateway_resource" "proxy" {
  for_each    = local.apis
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  parent_id   = aws_api_gateway_rest_api.this[each.key].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  for_each           = local.apis
  rest_api_id        = aws_api_gateway_rest_api.this[each.key].id
  resource_id        = aws_api_gateway_resource.proxy[each.key].id
  http_method        = "ANY"
  authorization      = "NONE"
  request_parameters = { "method.request.path.proxy" = true }
}

resource "aws_api_gateway_integration" "proxy" {
  for_each                = local.apis
  rest_api_id             = aws_api_gateway_rest_api.this[each.key].id
  resource_id             = aws_api_gateway_resource.proxy[each.key].id
  http_method             = aws_api_gateway_method.proxy[each.key].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "https://${each.value.host}/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.this[each.key].id
  request_parameters      = { "integration.request.path.proxy" = "method.request.path.proxy" }
  tls_config { insecure_skip_verification = true }
}
