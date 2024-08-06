
#https://docs.aws.amazon.com/ko_kr/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-permissions.html


data "aws_iam_policy_document" "assume_role_policy_doc" {
  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "rds.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "rds_policy_doc" {
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

resource "aws_iam_role_policy" "rds_role_policy" {
  name   = "RDSPolicy"
  role   = aws_iam_role.rds_role.id
  policy = data.aws_iam_policy_document.rds_policy_doc.json
}


resource "aws_iam_role" "rds_role" {
  name               = "RDSRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json
}