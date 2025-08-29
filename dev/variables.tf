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

# variables.tf - ADD THESE VARIABLES
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "dev-eks-cluster"
}

variable "eks_version" {
  type        = string
  description = "Kubernetes version for EKS"
  default     = "1.27"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for EKS"
  default     = []
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 3
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "instance_types" {
  type        = list(string)
  description = "List of instance types for worker nodes"
  default     = ["t3.medium"]
}

variable "disk_size" {
  type        = number
  description = "Disk size for worker nodes (GB)"
  default     = 20
}

variable "key_name" {
  type        = string
  description = "SSH key name for node access"
  default     = null
}

variable "github_runner_cidr" {
  type        = string
  description = "CIDR block of GitHub runner for access"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}