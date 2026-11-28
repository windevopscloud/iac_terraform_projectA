variable "environment" { type = string }
variable "aws_region" { type = string }
variable "cluster_name" { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }

variable "log_retention_days" {
  type        = number
  default     = 3
  description = "Retention for the container log groups (sandbox: keep it short)"
}

variable "trace_sampling_percentage" {
  type        = number
  default     = 100
  description = "Share of requests Istio traces (100 is fine for a small sandbox)"
}

variable "tags" { type = map(string) }
