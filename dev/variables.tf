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
  default     = "windevopscloud-terraform-bucket"
}

variable "state_table_name" {
  type    = string
  default = "windevopscloud-terraform-lock"
}

variable "create_github_runner" {
  description = "Whether to create GitHub runner EC2 instance"
  type        = string
  default     = "no"
}

variable "runner_instance_type" {
  description = "EC2 instance type for GitHub runner"
  type        = string
  default     = "t3.medium"
}

variable "github_organization" {
  description = "GitHub organization name (e.g., 'mycompany') or user name for personal account"
  type        = string
  default     = null
}

# Optional: If you want repository-level runners instead
variable "github_repository" {
  description = "GitHub repository URL for repository-level runner (e.g., 'mycompany/myrepo')"
  type        = string
  default     = null
}

variable "terraform_version" {
  description = "Terraform version to install"
  type        = string
  default     = "1.5.0"
}

variable "helm_version" {
  description = "Helm version to install"
  type        = string
  default     = "3.12.0"
}

variable "kubectl_version" {
  description = "kubectl version to install"
  type        = string
  default     = "1.27.0"
}

variable "node_version" {
  description = "Node.js version to install"
  type        = string
  default     = "18"
}