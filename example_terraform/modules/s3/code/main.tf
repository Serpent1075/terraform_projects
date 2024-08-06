resource "aws_s3_bucket" "codeseries" {
  bucket = "${var.prefix}-codeseries"
  tags = {
    Name        = "${var.prefix}-codeseries"
    Environment = "Dev"
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "codebucket_public_access_block" {
  bucket = aws_s3_bucket.codeseries.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = false
  restrict_public_buckets = false ##교차계정
  
}

resource "aws_s3_bucket_acl" "codeseries_acl" {
  bucket = aws_s3_bucket.codeseries.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codeseries_sse_conf" {
  bucket = aws_s3_bucket.codeseries.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms-arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "codeseries_versioning" {
  bucket = aws_s3_bucket.codeseries.id
  versioning_configuration {
    status = "Enabled" #"Disabled"
  }
}

resource "aws_s3_bucket_inventory" "codeseries_prefix" {
  bucket = aws_s3_bucket.codeseries.id
  name   = "DocumentsWeekly"

  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  filter {
    prefix = "/"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.codeseries.arn
      prefix     = "${var.prefix}-codeseries"
    }
  }
}