resource "aws_cloudwatch_log_group" "batchlambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}
