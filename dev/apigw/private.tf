# PRIVATE (corp) gateway: execute-api VPC endpoint, resource policy, private custom domain,
# access association, base path mapping, Route 53 private zone

resource "aws_api_gateway_rest_api_policy" "private" {
  for_each    = local.private_apis
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Principal = "*", Action = "execute-api:Invoke", Resource = "execute-api:/*" },
      { Effect = "Deny", Principal = "*", Action = "execute-api:Invoke", Resource = "execute-api:/*",
      Condition = { StringNotEquals = { "aws:SourceVpce" = aws_vpc_endpoint.execute_api.id } } }
    ]
  })
}

data "aws_region" "current" {}

data "aws_vpc" "this" { id = var.vpc_id }

resource "aws_security_group" "execute_api_vpce" {
  name_prefix = "${var.environment}-execute-api-vpce-"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_endpoint" "execute_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.execute_api_vpce.id]
  private_dns_enabled = false
  tags                = { Name = "${var.environment}-execute-api" }
}

resource "aws_api_gateway_domain_name" "private" {
  for_each             = local.private_apis
  domain_name          = each.value.host
  certificate_arn      = nonsensitive(data.aws_ssm_parameter.cert[each.key].value)
  security_policy      = "SecurityPolicy_TLS13_1_2_2021_06"
  endpoint_access_mode = "BASIC"
  endpoint_configuration { types = ["PRIVATE"] }
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Principal = "*", Action = "execute-api:Invoke", Resource = ["execute-api:/*"] },
      { Effect = "Deny", Principal = "*", Action = "execute-api:Invoke", Resource = ["execute-api:/*"],
      Condition = { StringNotEquals = { "aws:SourceVpce" = aws_vpc_endpoint.execute_api.id } } }
    ]
  })
}

resource "aws_api_gateway_domain_name_access_association" "private" {
  for_each                       = local.private_apis
  access_association_source      = aws_vpc_endpoint.execute_api.id
  access_association_source_type = "VPCE"
  domain_name_arn                = aws_api_gateway_domain_name.private[each.key].arn
}

resource "aws_api_gateway_base_path_mapping" "private" {
  for_each       = local.private_apis
  api_id         = aws_api_gateway_rest_api.this[each.key].id
  stage_name     = aws_api_gateway_stage.live[each.key].stage_name
  domain_name    = aws_api_gateway_domain_name.private[each.key].domain_name
  domain_name_id = aws_api_gateway_domain_name.private[each.key].domain_name_id
  depends_on     = [aws_api_gateway_domain_name_access_association.private]
}

resource "aws_route53_zone" "private" {
  for_each = local.private_apis
  name     = each.value.host
  vpc { vpc_id = var.vpc_id }
}

resource "aws_route53_record" "private" {
  for_each = local.private_apis
  zone_id  = aws_route53_zone.private[each.key].zone_id
  name     = each.value.host
  type     = "A"
  alias {
    name                   = aws_vpc_endpoint.execute_api.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.execute_api.dns_entry[0].hosted_zone_id
    evaluate_target_health = false
  }
}
