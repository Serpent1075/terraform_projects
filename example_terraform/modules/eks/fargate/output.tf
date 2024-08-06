output "endpoint" {
  value = aws_eks_cluster.kuber_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.kuber_cluster.certificate_authority[0].data
}

output "cluster_name" {
    value = aws_eks_cluster.kuber_cluster.name
}

output "iam_sa_role" {
  value = aws_iam_role.iam_sa_role.arn
}