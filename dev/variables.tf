variable "environment" {
  description = "POC environment"
  type        = string
  default     = "dev" # optional default value
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
