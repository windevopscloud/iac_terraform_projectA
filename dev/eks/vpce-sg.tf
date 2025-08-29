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

  tags = merge(var.tags, { Name = "vpc-endpoint-sg" })
}