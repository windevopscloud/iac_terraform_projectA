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

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -x  # Enable debugging

    # Update kubeconfig
    echo "Updating kubeconfig..."
    aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this.name}
    
    # Verify connection
    echo "Testing cluster connection..."
    kubectl cluster-info
   EOF
  )

  user_data_replace_on_change = true

  tags = {
    Name        = "eks_tools-${var.environment}"
    Environment = var.environment
  }

  depends_on = [
    aws_eks_cluster.this,      # Wait for cluster creation
    aws_eks_node_group.this,   # Wait for nodegroup creation
    kubernetes_config_map_v1_data.eks_tools_auth  # Wait for aws-auth configmap
  ]
}