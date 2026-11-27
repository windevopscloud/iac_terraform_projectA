variable "environment" { type = string }
variable "external_user_pool_arn" { type = string }
variable "corp_user_pool_arn" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "apihosts" { type = map(string) }
