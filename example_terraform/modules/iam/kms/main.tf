data "aws_iam_policy_document" "kms" {
  statement {
    sid = "AllowUseOfTheKey"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [
      "${var.kms_arn}"
    ]
  }
}

resource "aws_iam_policy" "kms" {
  name        = "${var.prefix}-kms-policy"
  path        = "/"
  description = ""
  policy      = "${data.aws_iam_policy_document.kms.json}"
}