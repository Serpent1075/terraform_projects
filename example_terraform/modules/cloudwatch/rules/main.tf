resource "aws_cloudwatch_event_rule" "schedule" {
  name        = "${var.prefix}-schedule"
  description = "schedule every period"

  schedule_expression = "cron(0 8 * * ? *)"
}


resource "aws_cloudwatch_event_rule" "signin" {
  name        = "${var.prefix}-capture-aws-sign-in"
  description = "Capture each AWS Console Sign In"

  event_pattern = <<EOF
    {
    "detail-type": [
        "AWS Console Sign In via CloudTrail"
    ]
    }
    EOF
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  arn  = var.lambda_arn
  rule = aws_cloudwatch_event_rule.schedule.id
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = var.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.schedule.arn
}