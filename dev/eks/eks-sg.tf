resource "aws_security_group" "eks_cluster_sg" {
  name_prefix = "${var.cluster_name}-cluster-sg"
  vpc_id      = data.aws_vpc.selected.id
  description = "Security group for EKS control plane"

  tags = merge(var.tags, { Name = "${var.cluster_name}-cluster-sg" })
}

# Allow worker nodes to communicate with control plane
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  security_group_id        = aws_security_group.eks_cluster_sg.id
  description              = "Allow Kubernetes API access from Nodes"
}

resource "aws_security_group_rule" "cluster_ingress_github_runner" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.github_runner.id
  security_group_id        = aws_security_group.eks_cluster_sg.id
  description              = "Allow Kubernetes API access from GitHub runner"
}

resource "aws_security_group_rule" "github_runner_egress_cluster" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = data.aws_security_group.github_runner.id
  description              = "Allow outbound to EKS API from GitHub runner"
}

################################################################
resource "aws_security_group" "eks_nodes_sg" {
  name_prefix = "${var.cluster_name}-nodes-sg"
  vpc_id      = data.aws_vpc.selected.id
  description = "Security group for EKS worker nodes with GitHub runner access"

  tags = merge(var.tags, { Name = "${var.cluster_name}-nodes-sg" })
}

resource "aws_security_group_rule" "nodes_ingress_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = aws_security_group.eks_nodes_sg.id
  description              = "Allow Kubernetes API access from Cluster"
}

# Allow all traffic between nodes (necessary for pod-to-pod communication)
resource "aws_security_group_rule" "nodes_ingress_nodes" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow Node access from Node"
}

# Allow NTP time sync (UDP 123 to Amazon Time Sync)
resource "aws_security_group_rule" "nodes_egress_ntp" {
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["169.254.169.123/32"] # Amazon Time Sync Service
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow NTP time synchronization"
}

# Allow egress to interface endpoints
resource "aws_security_group_rule" "nodes_egress_vpce" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [for subnet in data.aws_subnet.private_for_sg : subnet.cidr_block] # Only private subnets
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow VPCE access from Nodes"
}

# Allow egress to S3 via gateway endpoint
resource "aws_security_group_rule" "nodes_egress_s3" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow S3 access from Nodes"
}

resource "aws_security_group_rule" "nodes_ingress_github_runner" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.github_runner.id
  security_group_id        = aws_security_group.eks_nodes_sg.id
  description              = "Allow Node access from GitHub runner"
}

resource "aws_security_group_rule" "github_runner_egress_nodes" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  security_group_id        = data.aws_security_group.github_runner.id
  description              = "Allow outbound access to Nodes from GitHub runner"
}

