output "launch-template-id" {
  value = aws_launch_template.eks_worker_node_lt.id
  description = "launch template id"
}
output "launch-template-version" {
  value = aws_launch_template.eks_worker_node_lt.latest_version
  description = "launch template id"
}
