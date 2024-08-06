resource "aws_cloudwatch_event_rule" "resource_state" {
  name                = "runresourcestate"
  description         = "Run resource_state lambda function"
  schedule_expression = "cron(0 6 * * ? *)"
}


resource "aws_cloudwatch_event_target" "resource_state" {
  target_id = aws_cloudwatch_event_rule.resource_state.name
  arn  = var.lambda_arn
  rule = aws_cloudwatch_event_rule.resource_state.id
}

