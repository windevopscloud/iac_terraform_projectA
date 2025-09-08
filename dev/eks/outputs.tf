# outputs.tf
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.this.name
}

# Output for internal/external reference
output "eks_tools_instance_profile" {
  value = aws_iam_instance_profile.eks_tools.name
}