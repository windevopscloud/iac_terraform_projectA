variable "aws_region" {
  type = string
  #default = "us-east-1"
}

variable "environment" {
  type = string
  #default = "poc"
}

variable "state_bucket_name" {
  type        = string
  description = "Unique S3 bucket name for Terraform state"
  #default     = "windevopscloud-terraform-bucket"
}

variable "state_table_name" {
  type = string
  #default = "windevopscloud-terraform-lock"
}

# variables.tf - ADD THESE VARIABLES
variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  #default     = "dev-eks-cluster"
}

variable "eks_version" {
  type        = string
  description = "Kubernetes version for EKS"
  #default     = "1.30"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for EKS"
  #default     = []
}

variable "lt_desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  #default     = 2
}

variable "lt_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  #default     = 3
}

variable "lt_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  #default     = 1
}

variable "lt_instance_types" {
  type        = list(string)
  description = "List of instance types for worker nodes"
  #default     = ["t3.medium"]
}

variable "lt_disk_size" {
  type        = number
  description = "Disk size for worker nodes (GB)"
  #default     = 20
}

variable "lt_key_name" {
  type        = string
  description = "SSH key name for node access"
  #default     = null
}

variable "github_runner_cidr" {
  type        = string
  description = "CIDR block of GitHub runner for access"
  #default     = null
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  #default     = {}
}

variable "eks_addon_kube_proxy" {
  type        = string
  description = "Addon version for EKS"
  #default     = v1.30.14-eksbuild.8
}

variable "eks_addon_coredns" {
  type        = string
  description = "Addon version for EKS"
  #default     = v1.11.4-eksbuild.22
}

variable "eks_addon_vpc_cni" {
  type        = string
  description = "Addon version for EKS"
  #default     = v1.20.1-eksbuild.3
}
