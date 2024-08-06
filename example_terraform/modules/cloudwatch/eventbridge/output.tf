output "eventbridge_arn" {
    value = aws_cloudwatch_event_rule.partitioning.arn
}