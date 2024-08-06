locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.iam_for_glue.name
  policy_arn = element(local.role_policy_arns, count.index)
}


resource "aws_iam_role" "iam_for_glue" {
  name = "${var.prefix}-GlueRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


data "aws_iam_policy_document" "glue_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
  }
}

resource "aws_iam_role_policy" "glue_role_policy" {
  name   = "${var.prefix}-GluePolicy"
  role   = aws_iam_role.iam_for_glue.id
  policy = data.aws_iam_policy_document.glue_policy.json
}
