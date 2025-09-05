resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "coredns"
  addon_version     = "v1.11.4-eksbuild.22"
  resolve_conflicts = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "kube-proxy"
  addon_version     = "v1.30.14-eksbuild.8"
  resolve_conflicts = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "vpc-cni"
  addon_version     = "v1.20.1-eksbuild.3"
  resolve_conflicts = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}