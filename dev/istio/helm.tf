data "aws_caller_identity" "current" {}

locals {
  hub = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = "istio-system"
  create_namespace = true
  repository       = "https://blob.istio.io/istio-release/charts"
  chart            = "base"
  version          = var.istio_version
}

resource "helm_release" "istiod" {
  name       = "istiod"
  namespace  = "istio-system"
  repository = "https://blob.istio.io/istio-release/charts"
  chart      = "istiod"
  version    = var.istio_version
  wait       = false # the images are mirrored after this apply, like the LB controller

  set = [
    { name = "global.hub", value = local.hub },
    { name = "global.tag", value = var.istio_version },
    { name = "pilot.replicaCount", value = "1" },
    { name = "pilot.resources.requests.cpu", value = "100m" },
    { name = "pilot.resources.requests.memory", value = "512Mi" },
    { name = "meshConfig.outboundTrafficPolicy.mode", value = "REGISTRY_ONLY" },
  ]

  depends_on = [helm_release.istio_base]
  replace    = true
}