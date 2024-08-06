output "eventbridge_arn" {
    value = aws_cloudwatch_event_rule.resource_state.arn
}