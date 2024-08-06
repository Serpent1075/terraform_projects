resource "aws_s3_bucket" "cloudfront_s3" {
  bucket = "${var.prefix}-cloudfront-s3"
  
  tags = {
    Name        = "${var.prefix}-cloudfront-s3"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.cloudfront_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "cloudfront_s3_access_block" {
  bucket = aws_s3_bucket.cloudfront_s3.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = false
  restrict_public_buckets = false ##교차계정
  
}

resource "aws_s3_bucket_acl" "cloudfront_s3_acl" {
  bucket = aws_s3_bucket.cloudfront_s3.id
   access_control_policy {
    grant {
      grantee {
        id   = var.account_id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "READ_ACP"
    }

    owner {
      id = var.account_id
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_s3_versioning" {
  bucket = aws_s3_bucket.cloudfront_s3.id
  versioning_configuration {
    status = "Enabled" #"Disabled"
  }
}


