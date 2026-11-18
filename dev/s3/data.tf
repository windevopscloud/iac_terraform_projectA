data "aws_caller_identity" "current" {}

data "aws_iam_role" "github_runner" {
  name = "github-runner-${var.environment}-role"
}

data "aws_iam_role" "eks_tools" {
  name = "eks-tools-${var.environment}-role"
}