variable "environment" { type = string }
variable "aws_region" { type = string }

# Scopes each pool exposes. Written as "<service>.invoke"; tokens carry "<server>/<scope>".
variable "external_scopes" { type = list(string) }
variable "corp_scopes" { type = list(string) }

# One app client per caller: name => scopes that client may request.
variable "external_clients" { type = map(list(string)) }
variable "corp_clients" { type = map(list(string)) }

variable "tags" { type = map(string) }

variable "external_callback_urls" { type = list(string) }
variable "external_logout_urls" { type = list(string) }
variable "corp_callback_urls" { type = list(string) }
variable "corp_logout_urls" { type = list(string) }
variable "external_web_scopes" { type = list(string) }
variable "corp_web_scopes" { type = list(string) }
variable "external_test_users" { type = list(string) }
variable "corp_test_users" { type = list(string) }
variable "external_auth_domain" { type = string }
variable "corp_auth_domain" { type = string }