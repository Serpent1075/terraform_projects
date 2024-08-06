
#https://docs.aws.amazon.com/ko_kr/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-permissions.html


data "aws_iam_policy_document" "assume_role_policy_doc" {
  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "s3.amazonaws.com",
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda_logs_policy_doc" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "iam:CreateServiceLinkedRole",
      "lambda:GetFunction",
      "lambda:EnableReplication",
      "cloudfront:UpdateDistribution",
      "s3:ListBucket",
      "s3:GetObject"
    ]
  }
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
}

resource "aws_iam_role_policy" "logs_role_policy" {
  name   = "LambdaEdge-Policy"
  role   = aws_iam_role.lambda_at_edge.id
  policy = data.aws_iam_policy_document.lambda_logs_policy_doc.json
}


resource "aws_iam_role" "lambda_at_edge" {
  name               = "LambdaEdge-Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json
}