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
    resources  = ["pods", "configmaps", "services"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "eks_tools_binding" {
  metadata {
    name = "eks-tools-binding"
  }

  subject {
    kind      = "User"
    name      = aws_iam_role.eks_tools.arn
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.eks_tools.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# AWS Auth ConfigMap entry
resource "null_resource" "update_aws_auth" {
  triggers = {
    role_arn = aws_iam_role.eks_tools.arn
    always_run = timestamp() # Ensure it runs every time
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      # Wait a bit for cluster to be ready
      sleep 30
      
      # Check if mapping already exists
      if kubectl get configmap aws-auth -n kube-system -o yaml | grep -q "${aws_iam_role.eks_tools.arn}"; then
        echo "AWS auth mapping already exists, skipping..."
        exit 0
      fi

      # Add the new mapping
      echo "Adding IAM role to aws-auth ConfigMap..."
      kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup.yaml
      
      # Use yq to safely add the new entry
      cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  mapRoles: |
    $(kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapRoles}')
    - rolearn: ${aws_iam_role.eks_tools.arn}
      username: eks-tools-user
      groups:
      - eks-tools-group
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
EOF

      echo "AWS auth updated successfully!"
    EOT
  }

  depends_on = [
    aws_iam_role.eks_tools,
    kubernetes_cluster_role.eks_tools,
    kubernetes_cluster_role_binding.eks_tools_binding
  ]
}