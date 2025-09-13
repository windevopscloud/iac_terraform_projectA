# IAM Role
resource "aws_iam_role" "eks_tools" {
  name = "eks-tools-${var.environment}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach SSM for remote connection
resource "aws_iam_role_policy_attachment" "eks_tools_ssm" {
  role       = aws_iam_role.eks_tools.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach minimal EKS permissions for cluster info
resource "aws_iam_role_policy" "eks_tools_cluster_access" {
  name = "eks-tools-cluster-access"
  role = aws_iam_role.eks_tools.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "eks_tools" {
  name_prefix = "eks-tools-profile-"
  role        = aws_iam_role.eks_tools.name
}

#Kubernetes ClusterRole and ClusterRoleBinding
resource "kubernetes_cluster_role" "eks_tools" {
  metadata {
    name = "eks-tools-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "nodes", "namespaces", "configmaps", "events", "endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # For Ingress resources (inbound traffic)
  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  # For Network Policies (controls both ingress AND egress)
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  # For Calico Network Policies (if using Calico CNI)
  #rule {
  #  api_groups = ["crd.projectcalico.org"]
  #  resources  = ["networkpolicies", "globalnetworkpolicies"]
  #  verbs      = ["get", "list", "watch"]
  #}

  # For Cilium Network Policies (if using Cilium CNI)  
  #rule {
  #  api_groups = ["cilium.io"]
  #  resources  = ["ciliumnetworkpolicies", "ciliumclusterwidenetworkpolicies"]
  #  verbs      = ["get", "list", "watch"]
  #}

  # For Istio Egress Gateways (if using Istio)
  #rule {
  #  api_groups = ["networking.istio.io"]
  #  resources  = ["gateways", "virtualservices", "destinationrules"]
  #  verbs      = ["get", "list", "watch"]
  #}
}

resource "kubernetes_cluster_role_binding" "eks_tools_binding" {
  metadata {
    name = "eks-tools-binding"
  }

  subject {
    kind = "User"
    name = "eks-tools-user"
    #name      = aws_iam_role.eks_tools.arn
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.eks_tools.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}