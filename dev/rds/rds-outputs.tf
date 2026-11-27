output "db_endpoint" { value = aws_db_instance.this.address }
output "db_secret_arn" { value = aws_db_instance.this.master_user_secret[0].secret_arn }
output "db_security_group_id" { value = aws_security_group.rds.id }
output "isolated_subnet_ids" { value = data.aws_subnets.isolated.ids }
output "db_port" { value = aws_db_instance.this.port }
