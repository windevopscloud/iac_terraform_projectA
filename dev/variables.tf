variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "poc"
}

variable "state_bucket_name" {
  type        = string
  description = "Unique S3 bucket name for Terraform state"
  default     = "windevopscloud-terraform-s3"
}

variable "state_table_name" {
  type    = string
  default = "windevopscloud-terraform-lock"
}