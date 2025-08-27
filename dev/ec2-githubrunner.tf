resource "aws_instance" "github_runner" {
  count = var.create_github_runner == "yes" ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.runner_instance_type
  subnet_id     = data.terraform_remote_state.bootstrap.outputs.private_subnets[0] # Use first private subnet

  vpc_security_group_ids = [aws_security_group.github_runner.id]
  iam_instance_profile   = aws_iam_instance_profile.github_runner.name

  # Root volume
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/github-runner-userdata.sh", {
    github_org        = var.github_organization
    github_repo       = var.github_repository
    runner_name       = "private-runner-${var.environment}"
    labels            = "self-hosted,ubuntu,private,terraform,helm,k8s"
    terraform_version = var.terraform_version
    helm_version      = var.helm_version
    kubectl_version   = var.kubectl_version
    node_version      = var.node_version
  }))

  tags = {
    Name        = "github-runner-${var.environment}"
    Environment = var.environment
  }
}