# Shared: locals, lookups, REST APIs (ext + corp), VPC links, authorizers

locals {
  apis = {
    ext = {
      host     = var.apihosts.ext
      nlb_name = "${var.environment}-ext-nlb"
      pool_arn = var.external_user_pool_arn
      cert_ssm = "/${var.environment}/acm/extsvc-cert-arn"
      routes   = { extsvc1 = "ext-api/extsvc1.invoke", extsvc2 = "ext-api/extsvc2.invoke" }
      waf      = true
      rate     = 50
      burst    = 100
      private  = false
    }
    corp = {
      host     = var.apihosts.corp
      nlb_name = "${var.environment}-corp-nlb"
      pool_arn = var.corp_user_pool_arn
      cert_ssm = "/${var.environment}/acm/corpsvc-cert-arn"
      routes   = { corpsvc1 = "corp-api/corpsvc1.invoke", corpsvc2 = "corp-api/corpsvc2.invoke" }
      waf      = false
      rate     = 50
      burst    = 100
      private  = true
    }
  }

  routes = merge([
    for k, a in local.apis : {
      for r, scope in a.routes : "${k}-${r}" => { api = k, name = r, scope = scope }
    }
  ]...)

  waf_apis      = { for k, a in local.apis : k => a if a.waf }
  regional_apis = { for k, a in local.apis : k => a if !a.private }
  private_apis  = { for k, a in local.apis : k => a if a.private }
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

  lifecycle {
    ignore_changes = [target_arns]
  }
}

resource "aws_api_gateway_rest_api" "this" {
  for_each             = local.apis
  name                 = "${var.environment}-${each.key}-api"
  security_policy      = "SecurityPolicy_TLS13_1_2_2021_06"
  endpoint_access_mode = "BASIC"
  endpoint_configuration {
    types            = [each.value.private ? "PRIVATE" : "REGIONAL"]
    vpc_endpoint_ids = each.value.private ? [aws_vpc_endpoint.execute_api.id] : null
    ip_address_type  = each.value.private ? "dualstack" : null
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  for_each        = local.apis
  name            = "cognito"
  rest_api_id     = aws_api_gateway_rest_api.this[each.key].id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [each.value.pool_arn]
  identity_source = "method.request.header.Authorization"
}
