resource "aws_security_group" "vpc_endpoint_eks_sg" {
  name_prefix = "vpce-sg-eks"
  vpc_id      = data.aws_vpc.selected.id
  description = "Security group for VPC endpoints"

  # Allow HTTPS from private subnets
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in data.aws_subnet.private_for_sg : subnet.cidr_block] # Only private subnets
  }

  tags = merge(var.tags, { Name = "vpc-endpoint-sg-eks" })
}
