locals {
  apis = {
    ext = {
      host     = "intsvc.windevopscloud.com"
      nlb_name = "${var.environment}-ext-nlb"
      pool_arn = var.external_user_pool_arn
      cert_ssm = "/${var.environment}/acm/intsvc-cert-arn"
      routes   = { intsvc1 = "ext-api/intsvc1.invoke", intsvc2 = "ext-api/intsvc2.invoke" }
      waf      = true
      rate     = 50
      burst    = 100
    }
    corp = {
      host     = "corpsvc.windevopscloud.com"
      nlb_name = "${var.environment}-corp-nlb"
      pool_arn = var.corp_user_pool_arn
      cert_ssm = "/${var.environment}/acm/corpsvc-cert-arn"
      routes   = { corpsvc1 = "corp-api/corpsvc1.invoke", corpsvc2 = "corp-api/corpsvc2.invoke" }
      waf      = false
      rate     = 50
      burst    = 100
    }
  }

  routes = merge([
    for k, a in local.apis : {
      for r, scope in a.routes : "${k}-${r}" => { api = k, name = r, scope = scope }
    }
  ]...)

  waf_apis = { for k, a in local.apis : k => a if a.waf }
}

data "aws_lb" "nlb" {
  for_each = local.apis
  name     = each.value.nlb_name
}

data "aws_ssm_parameter" "cert" {
  for_each = local.apis
  name     = each.value.cert_ssm
}

resource "aws_api_gateway_vpc_link" "this" {
  for_each    = local.apis
  name        = "${var.environment}-${each.key}-vpclink"
  target_arns = [data.aws_lb.nlb[each.key].arn]
}

resource "aws_api_gateway_rest_api" "this" {
  for_each = local.apis
  name     = "${var.environment}-${each.key}-api"
  endpoint_configuration { types = ["REGIONAL"] }
}

resource "aws_api_gateway_authorizer" "cognito" {
  for_each        = local.apis
  name            = "cognito"
  rest_api_id     = aws_api_gateway_rest_api.this[each.key].id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [each.value.pool_arn]
  identity_source = "method.request.header.Authorization"
}

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

# ---- deploy, stage, throttling ----
resource "aws_api_gateway_deployment" "this" {
  for_each    = local.apis
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  triggers = {
    redeploy = sha1(jsonencode([
      each.value.routes,
      each.value.host,
      [for k, i in aws_api_gateway_integration.route : i.uri if local.routes[k].api == each.key],
      aws_api_gateway_integration.root[each.key].uri,
      aws_api_gateway_integration.proxy[each.key].uri,
    ]))
  }
  lifecycle { create_before_destroy = true }
  depends_on = [
    aws_api_gateway_integration.route,
    aws_api_gateway_integration.root,
    aws_api_gateway_integration.proxy,
  ]
}

resource "aws_api_gateway_stage" "live" {
  for_each      = local.apis
  rest_api_id   = aws_api_gateway_rest_api.this[each.key].id
  deployment_id = aws_api_gateway_deployment.this[each.key].id
  stage_name    = "live"
}

resource "aws_api_gateway_method_settings" "all" {
  for_each    = local.apis
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  stage_name  = aws_api_gateway_stage.live[each.key].stage_name
  method_path = "*/*"
  settings {
    throttling_rate_limit  = each.value.rate
    throttling_burst_limit = each.value.burst
  }
}

# ---- custom domains with the imported Let's Encrypt certs ----
resource "aws_api_gateway_domain_name" "this" {
  for_each                 = local.apis
  domain_name              = each.value.host
  regional_certificate_arn = nonsensitive(data.aws_ssm_parameter.cert[each.key].value)
  security_policy          = "TLS_1_2"
  endpoint_configuration { types = ["REGIONAL"] }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  for_each    = local.apis
  api_id      = aws_api_gateway_rest_api.this[each.key].id
  stage_name  = aws_api_gateway_stage.live[each.key].stage_name
  domain_name = aws_api_gateway_domain_name.this[each.key].domain_name
}

# ---- WAF on the external API ----
resource "aws_wafv2_web_acl" "this" {
  for_each = local.waf_apis
  name     = "${var.environment}-${each.key}-acl"
  scope    = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "common"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${each.key}-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-per-ip"
    priority = 2
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${each.key}-rate"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${each.key}-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  for_each     = local.waf_apis
  resource_arn = aws_api_gateway_stage.live[each.key].arn
  web_acl_arn  = aws_wafv2_web_acl.this[each.key].arn
}