resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = data.aws_subnets.private.ids
    endpoint_private_access = true  # Only accessible inside VPC
    endpoint_public_access  = false # Disable internet access
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.eks_cluster_name}-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = data.aws_subnets.private.ids

  scaling_config {
    desired_size = var.lt_desired_size
    max_size     = var.lt_max_size
    min_size     = var.lt_min_size
  }

  # Reference your launch template
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.ecr_readonly,
    aws_iam_role_policy_attachment.ssm_managed_instance
  ]
}

# Get the aws-auth configmap data
data "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  depends_on = [aws_eks_cluster.this]
}

# Add EKS tools IAM role to aws-auth
resource "kubernetes_config_map_v1_data" "eks_tools_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    "mapRoles" = yamlencode(concat(
      # Get existing mappings from the current aws-auth
      try(yamldecode(data.kubernetes_config_map.aws_auth.data.mapRoles), []),
      # Add our EKS tools mapping
      [{
        rolearn  = aws_iam_role.eks_tools.arn
        username = "eks-tools-user"
        groups   = ["eks-tools-group"]
      }]
    ))
  }

  lifecycle {
    ignore_changes = [data]
  }

  depends_on = [
    aws_eks_cluster.this,
    data.kubernetes_config_map.aws_auth,
    aws_iam_role.eks_tools
  ]
}

# Add EKS tools IAM role to aws-auth
resource "kubernetes_config_map_v1_data" "eks_tools_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    "mapRoles" = yamlencode(concat(
      # Get existing mappings
      try(yamldecode(data.kubernetes_config_map.aws_auth.data.mapRoles), []),
      # Add our EKS tools mapping
      [{
        rolearn  = aws_iam_role.eks_tools.arn
        username = "eks-tools-user"
        groups   = ["eks-tools-group"]
      }]
    ))
  }

  lifecycle {
    ignore_changes = [data]
  }

  depends_on = [
    aws_eks_cluster.this,
    data.kubernetes_config_map.aws_auth,
    aws_iam_role.eks_tools
  ]
}