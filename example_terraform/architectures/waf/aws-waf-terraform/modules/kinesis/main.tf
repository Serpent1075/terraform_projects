resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "aws-waf-logs-${var.stream_name}-${var.prefix}"
  destination = "extended_s3"
/*
  server_side_encryption{
    enabled = true
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn = var.kms_arn
  }
*/
  extended_s3_configuration {
    role_arn   = var.iam_arn
    bucket_arn = var.bucket_arn
    //kms_key_arn = var.kms_arn
    prefix              = var.s3_prefix
    error_output_prefix = "customernameerror/"
    buffer_size = 10
    buffer_interval = 120
    compression_format = "GZIP"
   
    cloudwatch_logging_options{
      enabled = true
      log_group_name = var.cloudwatch_log_group_name
      log_stream_name = var.cloudwatch_log_stream_name
    }
  }
/*
  s3_configuration {
    role_arn   = var.iam_arn
    bucket_arn = var.bucket_arn
    prefix = "waf-opensearch"
  }
  */
  tags = {
    Environment = "production"
    사용자 = "${var.user_tag}"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}