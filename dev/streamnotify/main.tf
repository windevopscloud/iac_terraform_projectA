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
      Resource = [var.smtp_secret_arn, aws_secretsmanager_secret.app.arn, aws_secretsmanager_secret.rds_app.arn]
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

resource "aws_secretsmanager_secret" "rds_app" {
  name                    = "streamnotify/${var.environment}/rds-app"
  recovery_window_in_days = 0
  tags                    = var.tags
}

# --- Dedicated app DB user: secret + automatic rotation (same design as signup) ---
# The database and the user are created in Postgres by streaming_app/deploy/db-bootstrap.sh.
resource "random_password" "db_app" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret_version" "rds_app" {
  secret_id = aws_secretsmanager_secret.rds_app.id
  secret_string = jsonencode({
    engine    = "postgres"
    host      = var.db_host
    port      = var.db_port
    dbname    = var.db_name
    username  = var.db_app_username
    password  = random_password.db_app.result
    masterarn = var.db_master_secret_arn
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Hosted rotation Lambda, reusing the rotation security group created in the secrets module
resource "aws_cloudformation_stack" "db_rotation" {
  name         = "streamnotify-db-rotation-${var.environment}"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_AUTO_EXPAND"]

  template_body = jsonencode({
    Transform = "AWS::SecretsManager-2020-07-23"
    Resources = {
      Rotation = {
        Type = "AWS::SecretsManager::RotationSchedule"
        Properties = {
          SecretId = aws_secretsmanager_secret.rds_app.arn
          HostedRotationLambda = {
            RotationType        = "PostgreSQLSingleUser"
            RotationLambdaName  = "streamnotify-db-rotation-${var.environment}"
            VpcSecurityGroupIds = var.rotation_security_group_id
            VpcSubnetIds        = join(",", var.isolated_subnet_ids)
          }
          RotationRules             = { ScheduleExpression = var.db_rotation_schedule }
          RotateImmediatelyOnUpdate = false # the DB user does not exist until the streaming deploy runs
        }
      }
    }
  })

  depends_on = [aws_secretsmanager_secret_version.rds_app]
}
