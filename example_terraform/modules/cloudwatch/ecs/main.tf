resource "aws_cloudwatch_log_group" "log_group" {
  name = "/aws/ecs/${var.prefix}-${var.name}"
  kms_key_id = var.cloudwatch_log_groups_kms_arn
}