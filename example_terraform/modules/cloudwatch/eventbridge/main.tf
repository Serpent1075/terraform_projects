resource "aws_cloudwatch_event_rule" "partitioning" {
  name                = "runpartitioning"
  description         = "Run partitioning lambda function"
  schedule_expression = "cron(0 6 * * ? *)"
}


resource "aws_cloudwatch_event_target" "partitioning" {
  target_id = aws_cloudwatch_event_rule.partitioning.name
  arn  = var.lambda_arn
  rule = aws_cloudwatch_event_rule.partitioning.id
}

