resource "aws_cloudwatch_log_group" "kinesis_log_group" {
  name              = "/aws/kinesis_firehose/${var.kinesis_name}-${var.prefix}"
  retention_in_days = 30

  tags = {
    사용자 = "${var.user_tag}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_cloudwatch_log_stream" "kinesis_log_stream" {
  name           = "DeliveryStream"
  log_group_name = aws_cloudwatch_log_group.kinesis_log_group.name
}