variable "create_github_runner" {
  description = "Whether to create GitHub runner EC2 instance"
  type        = string
  default     = "no"
}

variable "github_token" {
  description = "GitHub Personal Access Token for runner registration"
  type        = string
  sensitive   = true
}

variable "github_organization" {
  description = "GitHub organization or user name"
  type        = string
}

variable "runner_instance_type" {
  description = "EC2 instance type for GitHub runner"
  type        = string
  default     = "t3.medium"
}

variable "github_organization" {
  description = "GitHub organization name (e.g., 'mycompany') or user name for personal account"
  type        = string
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