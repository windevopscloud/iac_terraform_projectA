resource "aws_instance" "eks_tools" {

  ami           = var.eks_tools_ami_id
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