output "loggroup-arn" {
    value = aws_cloudwatch_log_group.log_group.arn
}

output "loggroup-id" {
    value = aws_cloudwatch_log_group.log_group.id
}