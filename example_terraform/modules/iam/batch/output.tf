
output "batch-iam-service-arn" {
  value = aws_iam_role.aws_batch_service_role.arn
}