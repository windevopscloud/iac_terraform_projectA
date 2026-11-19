data "aws_caller_identity" "current" {}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

resource "helm_release" "lbc" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.14.0"
  wait       = false

  set = [
    { name = "clusterName", value = var.cluster_name },
    { name = "region", value = var.aws_region },
    { name = "vpcId", value = data.aws_vpc.selected.id },
    { name = "replicaCount", value = "1" },
    { name = "image.repository", value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/aws-load-balancer-controller" },
    { name = "image.tag", value = "v2.14.1" },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = aws_iam_role.lbc.arn },
    { name = "enableShield", value = "false" },
    { name = "enableWaf", value = "false" },
    { name = "enableWafv2", value = "false" },
  ]

  depends_on = [aws_iam_role_policy_attachment.lbc]
}