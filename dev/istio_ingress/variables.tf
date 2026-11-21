variable "environment" { type = string }
variable "istio_version" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "node_security_group_id" { type = string }
variable "istiod_id" { type = string }