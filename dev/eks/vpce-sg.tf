resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "vpce-sg-eks"
  vpc_id      = data.aws_vpc.selected.id
  description = "Security group for VPC endpoints"

  # Allow HTTPS from nodes to endpoints
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes_sg.id]
  }

  # Allow DNS from nodes to endpoints
  ingress {
    from_port       = 53
    to_port         = 53
    protocol        = "udp"
    security_groups = [aws_security_group.eks_nodes_sg.id]
  }

  tags = merge(var.tags, { Name = "vpc-endpoint-sg-eks" })
}

# For vpce-sg-eks security group  
resource "aws_security_group_rule" "eks_vpce_allow_github_runner" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.github_runner.id
  security_group_id        = aws_security_group.vpc_endpoint.id  # vpce-sg-eks
  description              = "Allow HTTPS from GitHub runner to EKS VPC endpoints"
}

# For vpce-sg-ssm security group  
resource "aws_security_group_rule" "ssm_vpce_allow_github_runner" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.github_runner.id
  security_group_id        = data.aws_security_group.vpc_endpoint_ssm.id  # vpce-sg-ssm
  description              = "Allow HTTPS from GitHub runner to SSM VPC endpoints"
}