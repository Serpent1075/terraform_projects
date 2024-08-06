resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "aws-waf-logs-${var.prefix}"
  retention_in_days = 0

  tags = {
    사용자 = "${var.user_tag}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
