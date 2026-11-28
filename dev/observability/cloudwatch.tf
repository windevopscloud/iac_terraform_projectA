# ---- Amazon CloudWatch Observability add-on: container logs (Fluent Bit) + Container Insights metrics ----

locals {
  oidc_host = replace(var.oidc_provider_url, "https://", "")
}

# Log groups are created first so the retention is short; the add-on then writes into them.
resource "aws_cloudwatch_log_group" "container_insights" {
  for_each          = toset(["application", "dataplane", "host", "performance"])
  name              = "/aws/containerinsights/${var.cluster_name}/${each.key}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

data "aws_iam_policy_document" "cloudwatch_agent_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_agent" {
  name               = "${var.cluster_name}-cloudwatch-agent-role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_agent_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  service_account_role_arn = aws_iam_role.cloudwatch_agent.arn
  # no addon_version: EKS picks the default version for this cluster

  depends_on = [
    aws_cloudwatch_log_group.container_insights,
    aws_iam_role_policy_attachment.cloudwatch_agent,
  ]
}
