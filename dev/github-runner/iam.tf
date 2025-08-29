resource "aws_iam_role" "github_runner" {
  name_prefix = "GitHubRunnerRole-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "github-runner-role"
  }
}

resource "aws_iam_role_policy_attachment" "github_runner_ssm" {
  role       = aws_iam_role.github_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#resource "aws_iam_role_policy_attachment" "github_runner_ssm_automation" {
#  role       = aws_iam_role.github_runner.name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMAutomationRole"
#}

resource "aws_iam_instance_profile" "github_runner" {
  name_prefix = "github-runner-profile-"
  role        = aws_iam_role.github_runner.name
}


