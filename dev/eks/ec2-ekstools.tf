resource "aws_instance" "eks_tools" {

  ami           = data.aws_ami.eks_tools.id
  instance_type = var.eks_tools_instance_type
  subnet_id     = data.aws_subnets.private.ids[0] # Use first private subnet

  vpc_security_group_ids = [aws_security_group.eks_tools_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.eks_tools.name

  # Root volume
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data_replace_on_change = true

  tags = {
    Name        = "eks_tools-${var.environment}"
    Environment = var.environment
  }
}

resource "null_resource" "eks_tools_update_kubeconfig_ssm" {
  depends_on = [aws_instance.eks_tools, aws_eks_cluster.this]

  # This runs locally but sends command to EC2 via SSM
  provisioner "local-exec" {
    command = <<-EOT
      aws ssm send-command \
        --instance-ids ${aws_instance.eks_tools.id} \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this.name}"]' \
        --region ${var.aws_region}
    EOT
  }

  triggers = {
    cluster_arn = aws_eks_cluster.this.arn
    instance_id = aws_instance.eks_tools.id
  }
}