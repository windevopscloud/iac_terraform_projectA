variable "environment" { type = string }
variable "aws_region" { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "service_account_namespace" { type = string }
variable "service_account_name" { type = string }
variable "secret_arns" { type = list(string) }

variable "db_host" { type = string }
variable "db_port" { type = number }
variable "db_name" { type = string }
variable "db_master_secret_arn" { type = string }
variable "rds_security_group_id" { type = string }
variable "isolated_subnet_ids" { type = list(string) }
variable "db_app_username" {
  type    = string
  default = "signup_app"
}
variable "db_rotation_schedule" {
  type    = string
  default = "rate(4 hours)" # sandbox lives ~8h; use e.g. rate(30 days) elsewhere
}
variable "tags" { type = map(string) }
