locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
    "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = element(local.role_policy_arns, count.index)
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.prefix}-sqs-LambdaRole"

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


data "aws_iam_policy_document" "sqs_lambda_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
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
       "secretsmanager:GetSecretValue"
    ]
  }
}

resource "aws_iam_role_policy" "logs_role_policy" {
  name   = "${var.prefix}-sqs-LambdaPolicy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.sqs_lambda_policy.json
}
