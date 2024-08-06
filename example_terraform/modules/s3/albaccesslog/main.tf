resource "aws_s3_bucket" "albaccesslog" {
  bucket = "${var.prefix}-albaccesslog-s3"
  
  tags = {
    Name        = "${var.prefix}-albaccesslog-s3"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.albaccesslog.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.albaccesslog.arn}/*",
    ]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com","logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.albaccesslog.arn}/*",
    ]
    
    condition {
      test = "StringEquals"
      variable ="s3:x-amz-acl"

      values = ["bucket-owner-full-control"]
      
    }
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "${aws_s3_bucket.albaccesslog.arn}/*",
    ]
  }
}
