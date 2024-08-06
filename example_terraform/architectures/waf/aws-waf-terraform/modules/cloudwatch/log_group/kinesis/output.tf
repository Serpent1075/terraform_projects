output "loggroup_id" {
    value = aws_cloudwatch_log_group.kinesis_log_group.id
}

output "loggroup_name" {
    value = aws_cloudwatch_log_group.kinesis_log_group.name
}

output "logstream_name" {
    value = aws_cloudwatch_log_stream.kinesis_log_stream.name
}