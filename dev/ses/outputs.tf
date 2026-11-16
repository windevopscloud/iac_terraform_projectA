output "smtp_secret_arn" { value = aws_secretsmanager_secret.smtp.arn }
output "smtp_host"       { value = "email-smtp.${var.aws_region}.amazonaws.com" }