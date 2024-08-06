resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/${var.opensearch_name}-${var.prefix}"
  retention_in_days = 1

  tags = {
    사용자 = "${var.user_tag}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_cloudwatch_log_stream" "opensearch" {
  name           = "DeliveryStream"
  log_group_name = aws_cloudwatch_log_group.opensearch.name
}