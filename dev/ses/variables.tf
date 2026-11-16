variable "environment"            { type = string }
variable "aws_region"             { type = string }
variable "node_security_group_id" { type = string }
variable "ses_identities"         { type = list(string) }
variable "tags"                   { type = map(string) }