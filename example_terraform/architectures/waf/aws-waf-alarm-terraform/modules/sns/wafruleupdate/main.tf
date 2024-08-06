

resource "aws_sns_topic_subscription" "rule_update_alarm" {
  topic_arn = "arn:aws:sns:us-east-1:248400274283:aws-managed-waf-rule-notifications"
  protocol  = "lambda"
  endpoint  = var.lambda_arn
}