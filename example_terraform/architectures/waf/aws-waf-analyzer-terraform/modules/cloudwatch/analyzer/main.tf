resource "aws_cloudwatch_event_rule" "analyzer" {
  name                = "runanalyzer"
  description         = "Run analyzer lambda function"
  schedule_expression = "cron(0 10 1 * ? *)"
}


resource "aws_cloudwatch_event_target" "analyzer" {
  target_id = aws_cloudwatch_event_rule.analyzer.name
  arn  = var.lambda_arn
  rule = aws_cloudwatch_event_rule.analyzer.id
}

