output "eventbridge_arn" {
    value = aws_cloudwatch_event_rule.analyzer.arn
}