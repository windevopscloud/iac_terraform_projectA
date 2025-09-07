variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ami_name_prefix" {
  type    = string
  default = "eks-tools-ami"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "eks_version" {
  type = string
  default = 1.30.14
}

variable "kubectl_date" {
  type    = string
  default = "2025-08-03"
}

variable "eksctl_version" {
  type    = string
  default = "latest"
}

variable "helm_version" {
  type    = string
  default = "3.18.6"
}