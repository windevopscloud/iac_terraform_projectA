resource "kubernetes_namespace_v1" "egress" {
  metadata {
    name        = "istio-egress"
    annotations = { "poc/after-istiod" = var.istiod_id }
  }
}

resource "helm_release" "egress" {
  name       = "egress-gw"
  namespace  = kubernetes_namespace_v1.egress.metadata[0].name
  repository = "https://blob.istio.io/istio-release/charts"
  chart      = "gateway"
  version    = var.istio_version
  wait       = false

  values = [yamlencode({
    autoscaling  = { enabled = false }
    replicaCount = 1
    resources    = { requests = { cpu = "100m", memory = "128Mi" }, limits = { cpu = "1", memory = "512Mi" } }
    service = {
      type  = "ClusterIP"
      ports = [{ name = "tls-mtls", port = 443, targetPort = 8443, protocol = "TCP" }]
    }
  })]
}

# Nodes may only reach the VPC today. Allow HTTPS out via the NAT gateway (egress gateway and Cognito token calls).
resource "aws_security_group_rule" "nodes_egress_https" {
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.node_security_group_id
  description       = "HTTPS to the internet via NAT"
}