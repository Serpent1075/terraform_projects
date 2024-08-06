output "loggroup_id" {
    value = aws_cloudwatch_log_group.waf_log_group.id
}

output "loggroup_name" {
    value = aws_cloudwatch_log_group.waf_log_group.name
}

output "loggroup_arn" {
    value = aws_cloudwatch_log_group.waf_log_group.arn
}