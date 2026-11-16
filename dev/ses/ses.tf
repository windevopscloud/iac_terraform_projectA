# Secret container only. The value is set by hand, so the Gmail app password is never in Terraform or state.
resource "aws_secretsmanager_secret" "smtp" {
  name                    = "ses/${var.environment}/smtp"
  recovery_window_in_days = 0
  tags                    = var.tags
}

# Nodes have no internet rule; allow SMTP out through the NAT gateways
resource "aws_security_group_rule" "nodes_egress_smtp" {
  type              = "egress"
  from_port         = 587
  to_port           = 587
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.node_security_group_id
  description       = "SMTP to Gmail via NAT"
}