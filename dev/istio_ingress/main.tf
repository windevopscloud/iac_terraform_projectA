locals {
  gateways = {
    ext  = { name = "ingress-ext", namespace = "istio-ingress-ext", host = "intsvc.windevopscloud.com", public = false }
    corp = { name = "ingress-corp", namespace = "istio-ingress-corp", host = "corpsvc.windevopscloud.com", public = false }
    pub  = { name = "ingress-pub", namespace = "istio-ingress-pub", host = "extsvc.windevopscloud.com", public = true }
  }
}

resource "kubernetes_namespace_v1" "gw" {
  for_each = local.gateways
  metadata {
    name        = each.value.namespace
    annotations = { "poc/after-istiod" = var.istiod_id } # ordering only
  }
}

# Internal TLS cert for POC (self-signed). Terminates at the gateway.
resource "tls_private_key" "gw" {
  for_each  = local.gateways
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "gw" {
  for_each              = local.gateways
  private_key_pem       = tls_private_key.gw[each.key].private_key_pem
  dns_names             = [each.value.host]
  validity_period_hours = 8760
  allowed_uses          = ["key_encipherment", "digital_signature", "server_auth"]
  subject { common_name = each.value.host }
}

resource "kubernetes_secret_v1" "gw_tls" {
  for_each = local.gateways
  metadata {
    name      = "${each.key}-tls"
    namespace = kubernetes_namespace_v1.gw[each.key].metadata[0].name
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = tls_self_signed_cert.gw[each.key].cert_pem
    "tls.key" = tls_private_key.gw[each.key].private_key_pem
  }
}

resource "helm_release" "gw" {
  for_each   = local.gateways
  name       = each.value.name
  namespace  = kubernetes_namespace_v1.gw[each.key].metadata[0].name
  repository = "https://blob.istio.io/istio-release/charts"
  chart      = "gateway"
  version    = var.istio_version
  wait       = false

  values = [yamlencode({
    autoscaling  = { enabled = false }
    replicaCount = 1
    resources    = { requests = { cpu = "100m", memory = "128Mi" }, limits = { cpu = "1", memory = "512Mi" } }
    service = {
      type = each.value.public ? "ClusterIP" : "LoadBalancer"
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type"                              = "external"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"                   = "ip"
        "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internal"
        "service.beta.kubernetes.io/aws-load-balancer-name"                              = "${var.environment}-${each.key}-nlb"
        "service.beta.kubernetes.io/aws-load-balancer-subnets"                           = join(",", var.private_subnet_ids)
        "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
        "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol"              = "http"
        "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"                  = "15021"
        "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path"                  = "/healthz/ready"
      }
      ports = [{ name = "https", port = 443, targetPort = 8443, protocol = "TCP" }]
    }
  })]

  depends_on = [kubernetes_secret_v1.gw_tls]
}

# Security group rules on the worker nodes
data "aws_subnet" "private" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

resource "aws_security_group_rule" "nlb_to_gateway" {
  for_each          = toset(["8443", "15021"])
  type              = "ingress"
  protocol          = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  cidr_blocks       = [for s in data.aws_subnet.private : s.cidr_block]
  security_group_id = var.node_security_group_id
  description       = "NLB traffic and health check to Istio gateway pods"
}

# Pod to pod across nodes (xDS to istiod 15012, mTLS, gateway to app pods)
resource "aws_security_group_rule" "nodes_to_nodes" {
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = var.node_security_group_id
  security_group_id        = var.node_security_group_id
  description              = "Pod to pod across nodes (mesh)"
}