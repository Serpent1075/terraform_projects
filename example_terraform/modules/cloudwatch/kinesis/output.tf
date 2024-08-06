output "loggroup-id" {
    value = aws_cloudwatch_log_group.kinesis_log_group.id
}

output "loggroup-name" {
    value = aws_cloudwatch_log_group.kinesis_log_group.name
}

output "logstream-name" {
    value = aws_cloudwatch_log_stream.kinesis_log_stream.name
}