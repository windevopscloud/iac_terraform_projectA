resource "aws_security_group" "eks_nodes_sg" {
  name_prefix = "${var.cluster_name}-nodes-sg"
  vpc_id      = data.aws_vpc.selected.id
  description = "Security group for EKS worker nodes with GitHub runner access"

  tags = merge(var.tags, { Name = "${var.cluster_name}-nodes-sg" })
}

# Allow all outbound (necessary for nodes to download packages, communicate with ECR, etc.)
#resource "aws_security_group_rule" "nodes_egress_all" {
#  type              = "egress"
#  from_port         = 0
#  to_port           = 0
#  protocol          = "-1"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.eks_nodes_sg.id
#}

# Allow egress to interface endpoints (use CIDR blocks of the endpoint network interfaces)
resource "aws_security_group_rule" "nodes_egress_vpce_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block] # Restrict to VPC CIDR
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow egress to VPC endpoints over HTTPS"
}

# Allow egress to S3 via gateway endpoint
resource "aws_security_group_rule" "nodes_egress_s3" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow egress to S3"
}

# Allow DNS resolution (UDP 53 to VPC DNS)
resource "aws_security_group_rule" "nodes_egress_dns" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow DNS resolution within VPC"
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

# Optional: Allow limited internet access if absolutely necessary
# resource "aws_security_group_rule" "nodes_egress_limited_internet" {
#   type              = "egress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]  # Use specific IPs if possible
#   security_group_id = aws_security_group.eks_nodes_sg.id
#   description       = "Limited HTTPS internet access"
# }

# Allow all traffic between nodes (necessary for pod-to-pod communication)
resource "aws_security_group_rule" "nodes_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_nodes_sg.id
}

# Allow control plane to communicate with worker nodes on port 1025-65535
resource "aws_security_group_rule" "nodes_ingress_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = aws_security_group.eks_nodes_sg.id
}

# Allow SSH access from GitHub runner (if needed for debugging)
#resource "aws_security_group_rule" "nodes_ingress_ssh_from_runner" {
#  type              = "ingress"
#  from_port         = 22
#  to_port           = 22
#  protocol          = "tcp"
#  cidr_blocks       = [data.aws_vpc.selected.cidr_block]  # CIDR of your GitHub runner
#  description       = "Allow SSH from GitHub runner"
#  security_group_id = aws_security_group.eks_nodes_sg.id
#}

# Allow HTTPS from nodes to GitHub runner (if runner hosts internal services)
#resource "aws_security_group_rule" "nodes_egress_https_to_runner" {
#  type              = "egress"
#  from_port         = 443
#  to_port           = 443
#  protocol          = "tcp"
#  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
#  description       = "Allow HTTPS to GitHub runner"
#  security_group_id = aws_security_group.eks_nodes_sg.id
#}

# Allow Kubernetes API access from GitHub runner (for kubectl, helm, etc.)
resource "aws_security_group_rule" "cluster_ingress_api_from_runner" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  description       = "Allow Kubernetes API access from GitHub runner"
  security_group_id = aws_security_group.eks_cluster_sg.id # This goes on cluster SG
}

# Optional: Allow specific ports for custom services running on GitHub runner
resource "aws_security_group_rule" "nodes_ingress_custom_from_runner" {
  type              = "ingress"
  from_port         = 3000 # Example: Node.js app port
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  description       = "Allow custom service access from GitHub runner"
  security_group_id = aws_security_group.eks_nodes_sg.id
}

resource "aws_security_group_rule" "nodes_egress_limited_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Use specific IPs if possible
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Limited HTTPS internet access"
}

################################################################
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
}

