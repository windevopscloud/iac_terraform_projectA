# Shared: deployments, stages, throttling

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
      each.value.private ? aws_vpc_endpoint.execute_api.id : "",
    ]))
  }
  lifecycle { create_before_destroy = true }
  depends_on = [
    aws_api_gateway_integration.route,
    aws_api_gateway_integration.root,
    aws_api_gateway_integration.proxy,
    aws_api_gateway_rest_api_policy.private,
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
