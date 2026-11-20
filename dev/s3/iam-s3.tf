# Runner: upload bundles, and send a shell command to the tools EC2 only
resource "aws_iam_role_policy" "runner_bundles" {
  name = "bundles-upload-and-trigger"
  role = data.aws_iam_role.github_runner.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "UploadBundle"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.bundles.arn}/releases/*"
      },
      {
        Sid      = "UseRunShellScriptDocument"
        Effect   = "Allow"
        Action   = "ssm:SendCommand"
        Resource = "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"
      },
      {
        Sid      = "OnToolsInstanceOnly"
        Effect   = "Allow"
        Action   = "ssm:SendCommand"
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        Condition = {
          StringEquals = { "ssm:resourceTag/Name" = "eks_tools-${var.environment}" }
        }
      }
    ]
  })
}

# Tools EC2: read bundles only
resource "aws_iam_role_policy" "tools_bundles" {
  name = "bundles-read"
  role = var.eks_tools_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.bundles.arn}/releases/*"
    }]
  })
}