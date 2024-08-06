output "kuber-cluster-role-arn" {
    value = aws_iam_role.kuber_role.arn
}

output "kuber_load_balancer_controller_policy_arn" {
    value = aws_iam_policy.kuber_load_balancer_controller_policy.arn
}