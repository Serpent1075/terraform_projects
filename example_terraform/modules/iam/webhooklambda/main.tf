locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = element(local.role_policy_arns, count.index)
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "LambdaRole-${var.prefix}"

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


data "aws_iam_policy_document" "codebuild_lambda_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "batch:SubmitJob",
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages",
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectVersion"
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
  name   = "LambdaPolicy-${var.prefix}"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.codebuild_lambda_policy.json
}
