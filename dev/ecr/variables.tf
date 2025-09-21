variable "aws_region" {
  type        = string
  description = "AWS region"
  #default     = "us-east-1"
}

variable "environment" {
  type = string
  #default = "poc"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  #default     = {}
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  #default     = "dev-eks-cluster"
}

variable "ecr_repos" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = []
}