variable "aws_region" { type = string }
variable "istio_version" { type = string }

# Not used directly: passing the OIDC ARN makes Istio install after the EKS cluster exists,
# the same way the lbcontroller module is ordered.
variable "oidc_provider_arn" { type = string }