resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.prefix}-analyzer-LambdaRole"
   managed_policy_arns = [data.aws_iam_policy.lambda_basic_execution_role_policy.arn]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy" "lambda_basic_execution_role_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents",
       "logs:PutMetricFilter",
       "logs:PutRetentionPolicy"
    ]
  }
  
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "athena:*",
      "glue:*"
    ]
  }
  statement {
    effect    = "Allow"
    resources = [
      "${var.s3_arn}",
      "${var.s3_arn}/output",
      "${var.s3_arn}/output/*",
    ]
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:CreateBucket",
      "s3:PutObject"
    ]
  }
   statement {
    effect    = "Allow"
    resources = [
      "${var.s3_arn}/AWSLogs/*"
    ]
    actions = [
      "s3:GetObject"
    ]
  }
}

resource "aws_iam_role_policy" "logs_role_policy" {
  name   = "${var.prefix}-analyzer-LambdaPolicy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}
