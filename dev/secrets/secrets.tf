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