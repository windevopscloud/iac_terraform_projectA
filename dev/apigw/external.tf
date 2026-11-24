# EXTERNAL gateway (REGIONAL): custom domain, base path mapping, WAF

# ---- custom domains with the imported Let's Encrypt certs ----
resource "aws_api_gateway_domain_name" "this" {
  for_each                 = local.regional_apis
  domain_name              = each.value.host
  regional_certificate_arn = nonsensitive(data.aws_ssm_parameter.cert[each.key].value)
  security_policy          = "SecurityPolicy_TLS13_1_2_2021_06"
  endpoint_access_mode     = "BASIC"
  endpoint_configuration { types = ["REGIONAL"] }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  for_each    = local.regional_apis
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
