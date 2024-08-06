resource "aws_athena_database" "waflogs" {
  name   = "aws_waf_logs_db"
  bucket = var.s3_bucket_id
}

resource "aws_athena_workgroup" "waflogs" {
  name = "aws-waf-logs-${var.prefix}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
   

    result_configuration {
      output_location = "s3://${var.s3_bucket_name}/output"
     acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
     }

     encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
