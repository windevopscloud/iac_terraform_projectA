variable "environment" { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "smtp_secret_arn" { type = string }
variable "service_account_namespace" {
  type    = string
  default = "default"
}
variable "service_account_name" {
  type    = string
  default = "streamnotify"
}
variable "db_host" { type = string }
variable "db_port" { type = number }
variable "db_master_secret_arn" { type = string }
variable "rotation_security_group_id" { type = string }
variable "isolated_subnet_ids" { type = list(string) }
variable "db_name" {
  type    = string
  default = "streamnotify"
}
variable "db_app_username" {
  type    = string
  default = "streaming_app"
}
variable "db_rotation_schedule" {
  type    = string
  default = "rate(4 hours)"
}
variable "tags" { type = map(string) }
