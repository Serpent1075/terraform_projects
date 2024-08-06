locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  ]
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = var.role_name
  policy_arn = element(local.role_policy_arns, count.index)
}
