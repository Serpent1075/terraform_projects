output "loggroup_id" {
    value = aws_cloudwatch_log_group.opensearch.id
}

output "loggroup_name" {
    value = aws_cloudwatch_log_group.opensearch.name
}
output "loggroup_arn" {
    value = aws_cloudwatch_log_group.opensearch.arn
}
output "logstream_name" {
    value = aws_cloudwatch_log_stream.opensearch.name
}