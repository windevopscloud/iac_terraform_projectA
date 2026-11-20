data "aws_caller_identity" "current" {}

data "aws_iam_role" "github_runner" {
  name = "github-runner-${var.environment}-role"
}