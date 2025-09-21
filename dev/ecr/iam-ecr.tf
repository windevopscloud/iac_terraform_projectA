resource "aws_ecr_repository_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowVPCEndpointAccess",
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ],
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = [
              data.aws_vpc_endpoint.ecr_dkr.id,
              data.aws_vpc_endpoint.ecr_api.id
            ]
          }
        }
      },
      {
        Sid    = "AllowEKSWorkerNodesPull",
        Effect = "Allow",
        Principal = {
          AWS = data.aws_iam_role.eks_nodes.arn
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
      },
      {
        Sid    = "AllowEKSAdminPushPull",
        Effect = "Allow",
        Principal = {
          AWS = [
            data.aws_iam_role.eks_tools.arn,
            data.aws_iam_role.github_runner.arn
          ]
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
      }
    ]
  })
}