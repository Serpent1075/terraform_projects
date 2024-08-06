resource "aws_s3_bucket" "waf_log_bucket" {
  bucket = "aws-waf-logs-${var.prefix}"
}

resource "aws_s3_bucket_public_access_block" "log_bucket_public_access_block" {
  bucket = aws_s3_bucket.waf_log_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true ##교차계정
  
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.waf_log_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_sse_conf" {
  bucket = aws_s3_bucket.waf_log_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_arn
      sse_algorithm     = "aws:kms"
    }
  }
}