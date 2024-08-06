
#S3 버킷
resource "aws_s3_bucket" "region" {
  bucket = "aws-waf-logs-${var.prefix}"
  
  tags = {
    Name = "aws-waf-logs-${var.prefix}"
    사용자 = "${var.user_tag}"
  }
}

#버킷 버저닝 활성화 여부
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.region.id
  versioning_configuration {
    status = "Enabled" //Disabled
  }
}

#버킷 퍼블릭 차단
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "region_s3_access_block" {
  bucket = aws_s3_bucket.region.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = false
  restrict_public_buckets = false ##교차계정 
}


resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.region.id

  rule {
    id = "waflog"

    expiration {
      days = 180
    }

    filter {
    }

    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 120
      storage_class = "GLACIER"
    }
  }
}
/*
resource "aws_s3_bucket_policy" "allow_access" {
  bucket = aws_s3_bucket.region.id
  policy = data.aws_iam_policy_document.allow_access.json
}

data "aws_iam_policy_document" "allow_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.account_id]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.region.arn,
      "${aws_s3_bucket.region.arn}/*",
    ]
  }
}
*/