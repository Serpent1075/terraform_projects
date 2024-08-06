provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

resource "aws_s3_bucket" "lambdaedge_s3" {
  provider = aws.virginia
  bucket = "${var.prefix}-lambdaedge-s3"
  
  tags = {
    Name        = "${var.prefix}-lambdaedge-s3"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  provider = aws.virginia
  bucket = aws_s3_bucket.lambdaedge_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "lambdaedge_s3_access_block" {
  provider = aws.virginia
  bucket = aws_s3_bucket.lambdaedge_s3.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = false
  restrict_public_buckets = false ##교차계정
  
}

resource "aws_s3_bucket_acl" "lambdaedge_s3_acl" {
  provider = aws.virginia
  bucket = aws_s3_bucket.lambdaedge_s3.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambdaedge_s3_conf" {
  provider = aws.virginia
  bucket = aws_s3_bucket.lambdaedge_s3.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_arn
      sse_algorithm     = "aws:kms"
    }
  }
}


resource "aws_s3_bucket_versioning" "lambdaedge_s3_versioning" {
  provider = aws.virginia
  bucket = aws_s3_bucket.lambdaedge_s3.id
  versioning_configuration {
    status = "Enabled" #"Disabled"
  }
}


