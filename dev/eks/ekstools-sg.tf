resource "aws_security_group" "eks_tools_sg" {
  name_prefix = "${var.eks_cluster_name}-tools-sg"
  vpc_id      = data.aws_vpc.selected.id
  description = "Security group for EKS tools EC2"

  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-tools-sg" })
}

resource "aws_security_group_rule" "cluster_ingress_eks_tools" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_tools_sg.id
  security_group_id        = aws_security_group.eks_cluster_sg.id
  description              = "Allow Kubernetes API access from EKS tools"
}

resource "aws_security_group_rule" "eks_tools_egress_cluster" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = aws_security_group.eks_tools_sg.id
  description              = "Allow outbound to EKS API from EKS tools"
}

# Allow egress to interface endpoints
resource "aws_security_group_rule" "eks_tools_egress_vpce" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [for subnet in data.aws_subnet.private_for_sg : subnet.cidr_block] # Only private subnets
  security_group_id = aws_security_group.eks_tools_sg.id
  description       = "Allow VPCE access from Nodes"
}
