#신뢰관계
data "aws_iam_policy_document" "assume_role_policy_doc" {
  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        var.account_id,
      ]
    }

    principals {
      type = "Service"

      identifiers = [
        "firehose.amazonaws.com"
      ]
    }
  }
}

#정책문
data "aws_iam_policy_document" "kinesis_policy_doc" {

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
    ]

    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    resources = [
      "arn:aws:firehose:${var.aws_region}:${var.account_id}:delivery/${var.stream_name}-${var.prefix}"
      ]
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
  }

  
  statement {
    effect    = "Allow"
    resources =  [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/kinesis/${var.stream_name}-${var.prefix}:log-stream:*"
      ]
    actions = [
      "logs:PutLogEvents"
    ]
   }
   statement {
    effect    = "Allow"
    resources = [ 
        "arn:aws:s3:::${var.bucketname}",
        "arn:aws:s3:::${var.bucketname}/*"
    ]
    actions = [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
    ]
  }

}

#위 정책문대로 생성할 정책, 역할지정
resource "aws_iam_role_policy" "kinesis_role_policy" {
  name   = "${var.prefix}-KinesisPolicy"
  role   = aws_iam_role.kinesis_role.id
  policy = data.aws_iam_policy_document.kinesis_policy_doc.json
}


#역할
resource "aws_iam_role" "kinesis_role" {
  name               = "${var.prefix}-KinesisRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json

  tags = {
    사용자 = "${var.user_tag}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}



/*
  statement {
    effect    = "Allow"
    resources = [
      "${var.kms_arn}"
    ]
    actions = [
       "kms:Decrypt",
       "kms:GenerateDataKey"
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "s3.${var.aws_region}.amazonaws.com",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"

      values = [
        "arn:aws:s3:::${var.bucketname}/waflog*",
      ]
    }
  }
  */