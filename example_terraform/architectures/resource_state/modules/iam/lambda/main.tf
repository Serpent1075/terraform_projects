resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.prefix}-resource-state-LambdaRole"

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
    resources = var.kms_arns
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]
  }
}

resource "aws_iam_role_policy" "logs_role_policy" {
  name   = "${var.prefix}-resource-state-LambdaPolicy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}
