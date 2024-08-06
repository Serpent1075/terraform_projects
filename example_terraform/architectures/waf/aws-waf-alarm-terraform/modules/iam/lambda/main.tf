locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess",
  ]
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = element(local.role_policy_arns, count.index)
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.prefix}-sns-LambdaRole"

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


data "aws_iam_policy_document" "sns_lambda_policy" {
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
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
  }
  
}

resource "aws_iam_role_policy" "logs_role_policy" {
  name   = "${var.prefix}-sns-LambdaPolicy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.sns_lambda_policy.json
}
