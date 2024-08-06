#신뢰관계
data "aws_iam_policy_document" "assume_role_policy_doc" {
  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]
    
    principals {
      type = "Service"

      identifiers = [
        "s3.amazonaws.com"
      ]
    }
  }
}

#정책문
data "aws_iam_policy_document" "snowflake_policy_doc" {

  statement {
    effect = "Allow"

    actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetObjectVersion"
    ]

    resources = ["${var.s3_arn}","${var.s3_arn}/*"]
  }
}

#위 정책문대로 생성할 정책, 역할지정
resource "aws_iam_role_policy" "snowflake_role_policy" {
  name   = "${var.prefix}-SnowflakePolicy"
  role   = aws_iam_role.snowflake_role.id
  policy = data.aws_iam_policy_document.snowflake_policy_doc.json
}

#역할
resource "aws_iam_role" "snowflake_role" {
  name               = "${var.prefix}-SnowflakeRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json

  tags = {
    사용자 = "${var.user_tag}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
