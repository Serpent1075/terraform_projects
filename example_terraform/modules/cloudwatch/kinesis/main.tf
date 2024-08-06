resource "aws_cloudwatch_log_group" "kinesis_log_group" {
  name              = "/aws/kinesis_firehose/${var.prefix}-${var.kinesis_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_stream" "kinesis_log_stream" {
  name           = "DeliveryStream"
  log_group_name = aws_cloudwatch_log_group.kinesis_log_group.name
}