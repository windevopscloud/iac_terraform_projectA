# Get existing IAM roles
data "aws_iam_role" "eks_nodes" {
  name = "${var.eks_cluster_name}-eks-nodegroup-role"
}

data "aws_iam_role" "eks_tools" {
  name = "eks-tools-${var.environment}-role"
}

data "aws_iam_role" "github_runner" {
  name = "GitHubRunnerRole-*"
}

# Get existing VPC endpoints
data "aws_vpc_endpoint" "ecr_dkr" {
  filter {
    name   = "tag:Name"
    values = ["ecr-dkr-vpc-endpoint"]
  }
}

data "aws_vpc_endpoint" "ecr_api" {
  filter {
    name   = "tag:Name"
    values = ["ecr-api-vpc-endpoint"]
  }
}

data "aws_region" "current" {}