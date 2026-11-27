# --- Private path to Secrets Manager (nodes have no internet) ---
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["private-*"]
  }
}

data "aws_subnet" "private_for_sg" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

resource "aws_security_group" "secretsmanager_vpce" {
  name_prefix = "vpce-sg-secretsmanager-"
  vpc_id      = data.aws_vpc.selected.id
  description = "Secrets Manager endpoint"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for s in data.aws_subnet.private_for_sg : s.cidr_block]
  }

  tags = merge(var.tags, { Name = "vpc-endpoint-sg-secretsmanager" })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = data.aws_vpc.selected.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.secretsmanager_vpce.id]
  tags                = merge(var.tags, { Name = "secretsmanager-vpc-endpoint" })
}

resource "aws_secretsmanager_secret" "rds_app" {
  name                    = "signup/poc/rds-app"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "signup/poc/app"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "random_password" "app_secret_key" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id     = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({ SECRET_KEY = random_password.app_secret_key.result })
}

# --- Dedicated app DB user: secret + automatic rotation ---
# The user itself is created in Postgres by signup_app/deploy/db-bootstrap.sh (runs on the tools EC2).
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

  # rotation changes the password; do not let Terraform put the old one back
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Rotation Lambda (AWS hosted, single-user strategy) runs in the isolated subnets next to RDS
resource "aws_security_group" "db_rotation" {
  name_prefix = "signup-db-rotation-${var.environment}-"
  description = "Secrets Manager rotation Lambda"
  vpc_id      = data.aws_vpc.selected.id
  tags        = merge(var.tags, { Name = "signup-db-rotation-sg" })
}

resource "aws_security_group_rule" "rotation_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.rds_security_group_id
  security_group_id        = aws_security_group.db_rotation.id
  description              = "Postgres to RDS"
}

resource "aws_security_group_rule" "rotation_to_vpce" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.secretsmanager_vpce.id
  security_group_id        = aws_security_group.db_rotation.id
  description              = "Secrets Manager endpoint"
}

resource "aws_security_group_rule" "rds_from_rotation" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_rotation.id
  security_group_id        = var.rds_security_group_id
  description              = "Postgres from rotation Lambda"
}

resource "aws_security_group_rule" "vpce_from_rotation" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_rotation.id
  security_group_id        = aws_security_group.secretsmanager_vpce.id
  description              = "Rotation Lambda to Secrets Manager"
}

# Terraform has no resource for hosted rotation, so it goes through a small CloudFormation stack
resource "aws_cloudformation_stack" "db_rotation" {
  name         = "signup-db-rotation-${var.environment}"
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
            RotationLambdaName  = "signup-db-rotation-${var.environment}"
            VpcSecurityGroupIds = aws_security_group.db_rotation.id
            VpcSubnetIds        = join(",", var.isolated_subnet_ids)
          }
          RotationRules             = { ScheduleExpression = var.db_rotation_schedule }
          RotateImmediatelyOnUpdate = false # the DB user does not exist until the signup deploy runs
        }
      }
    }
  })

  depends_on = [
    aws_secretsmanager_secret_version.rds_app,
    aws_vpc_endpoint.secretsmanager,
    aws_security_group_rule.rotation_to_rds,
    aws_security_group_rule.rotation_to_vpce,
    aws_security_group_rule.rds_from_rotation,
    aws_security_group_rule.vpce_from_rotation,
  ]
}
