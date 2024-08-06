provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "log_group" {
  provider = aws.virginia
  name = "/aws/lambda/${var.prefix}-${var.name}"
  kms_key_id = var.cloudwatch_log_groups_kms_arn
}