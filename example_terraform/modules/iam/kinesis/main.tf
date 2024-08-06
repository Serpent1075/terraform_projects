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

data "aws_iam_policy_document" "kinesis_policy_doc" {
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

  statement {
    effect    = "Allow"
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/${var.stream_name}"
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
    resources = [
        "arn:aws:glue:${var.aws_region}:${var.account_id}:catalog",
        "arn:aws:glue:${var.aws_region}:${var.account_id}:database/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
        "arn:aws:glue:${var.aws_region}:${var.account_id}:table/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    ]
    actions = [
        "glue:GetTable",
        "glue:GetTableVersion",
        "glue:GetTableVersions"
    ]
  }

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

  statement {
    effect    = "Allow"
    resources =  [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/kinesis/${var.stream_name}:log-stream:*"
      ]
    actions = [
      "logs:PutLogEvents"
    ]
   }

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
        "kinesis.${var.aws_region}.amazonaws.com",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:kinesis:arn"

      values = [
        "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
      ]
    }
  }
}

resource "aws_iam_role_policy" "kinesis_role_policy" {
  name   = "KinesisPolicy"
  role   = aws_iam_role.kinesis_role.id
  policy = data.aws_iam_policy_document.kinesis_policy_doc.json
}


resource "aws_iam_role" "kinesis_role" {
  name               = "KinesisRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json
}