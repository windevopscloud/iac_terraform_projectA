# ---- ADOT add-on (OpenTelemetry operator) + collector that sends traces to AWS X-Ray ----

# The ADOT add-on needs cert-manager (webhook certificates)
resource "aws_eks_addon" "cert_manager" {
  cluster_name = var.cluster_name
  addon_name   = "cert-manager"
}

resource "aws_eks_addon" "adot" {
  cluster_name = var.cluster_name
  addon_name   = "adot"

  depends_on = [aws_eks_addon.cert_manager]
}

data "aws_iam_policy_document" "otel_collector_assume" {
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
      values   = ["system:serviceaccount:observability:otel-collector"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "otel_collector" {
  name               = "${var.cluster_name}-otel-collector-role"
  assume_role_policy = data.aws_iam_policy_document.otel_collector_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "otel_collector_xray" {
  role       = aws_iam_role.otel_collector.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# Local chart: ServiceAccount (IRSA), the OpenTelemetryCollector resource and the Istio Telemetry resource.
# A chart is used so Terraform does not need the operator's CRDs at plan time.
resource "helm_release" "otel" {
  name             = "otel"
  namespace        = "observability"
  create_namespace = true
  chart            = "${path.module}/otel-chart"

  set = [
    { name = "roleArn", value = aws_iam_role.otel_collector.arn },
    { name = "region", value = var.aws_region },
    { name = "samplingPercentage", value = tostring(var.trace_sampling_percentage) },
  ]

  depends_on = [
    aws_eks_addon.adot,
    aws_iam_role_policy_attachment.otel_collector_xray,
  ]
}
