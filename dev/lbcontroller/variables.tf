variable "environment" { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "tags" { type = map(string) }
variable "cluster_name" { type = string }
variable "aws_region" { type = string }