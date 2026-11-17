variable "environment" { type = string }
variable "aws_region" { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "service_account_namespace" { type = string }
variable "service_account_name" { type = string }
variable "secret_arns" { type = list(string) }
variable "tags" { type = map(string) }