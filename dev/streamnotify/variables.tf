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
variable "tags" { type = map(string) }