# IRSA role for the streamnotify ServiceAccount: read the existing SMTP secret only.
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "streamnotify-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "smtp" {
  name = "streamnotify-read-smtp-secret"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [var.smtp_secret_arn, aws_secretsmanager_secret.app.arn]
    }]
  })
}

output "role_arn" { value = aws_iam_role.app.arn }

resource "aws_secretsmanager_secret" "app" {
  name                    = "streamnotify/${var.environment}/app"
  recovery_window_in_days = 0
  tags                    = var.tags
}
resource "random_password" "secret_key" {
  length  = 64
  special = false
}
resource "random_password" "publish_key" {
  length  = 32
  special = false
}
resource "aws_secretsmanager_secret_version" "app" {
  secret_id     = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({ SECRET_KEY = random_password.secret_key.result, PUBLISH_KEY = random_password.publish_key.result })
}