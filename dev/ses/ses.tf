# 1. Identities (sender + sandbox recipients). Each one gets a verification e-mail to click.
resource "aws_sesv2_email_identity" "this" {
  for_each       = toset(var.ses_identities)
  email_identity = each.value
  tags           = var.tags
}

# 2. SMTP user the app logs in with
resource "aws_iam_user" "smtp" {
  name = "ses-smtp-${var.environment}"
}

resource "aws_iam_user_policy" "smtp" {
  user = aws_iam_user.smtp.name
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "ses:SendRawEmail", Resource = "*" }]
  })
}

resource "aws_iam_access_key" "smtp" {
  user = aws_iam_user.smtp.name
}

# 3. Store the SMTP login in Secrets Manager (ESO reads it later)
resource "aws_secretsmanager_secret" "smtp" {
  name                    = "signup/${var.environment}/smtp"
  recovery_window_in_days = 0 # poc: allow immediate delete/recreate
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "smtp" {
  secret_id = aws_secretsmanager_secret.smtp.id
  secret_string = jsonencode({
    SMTP_USER     = aws_iam_access_key.smtp.id
    SMTP_PASSWORD = aws_iam_access_key.smtp.ses_smtp_password_v4
  })
}

# 4. Private path to SES SMTP (nodes have no internet)
resource "aws_security_group" "smtp_vpce" {
  name_prefix = "vpce-sg-smtp-"
  vpc_id      = data.aws_vpc.selected.id
  description = "SES SMTP endpoint"
  tags        = merge(var.tags, { Name = "vpc-endpoint-sg-smtp" })
}

resource "aws_security_group_rule" "smtp_vpce_ingress_nodes" {
  type                     = "ingress"
  from_port                = 587
  to_port                  = 587
  protocol                 = "tcp"
  source_security_group_id = var.node_security_group_id
  security_group_id        = aws_security_group.smtp_vpce.id
  description              = "SMTP from EKS nodes"
}

resource "aws_security_group_rule" "nodes_egress_smtp" {
  type                     = "egress"
  from_port                = 587
  to_port                  = 587
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.smtp_vpce.id
  security_group_id        = var.node_security_group_id
  description              = "SMTP to SES endpoint"
}

resource "aws_vpc_endpoint" "smtp" {
  vpc_id              = data.aws_vpc.selected.id
  service_name        = "com.amazonaws.${var.aws_region}.email-smtp"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.smtp_vpce.id]
  tags                = merge(var.tags, { Name = "email-smtp-vpc-endpoint" })
}