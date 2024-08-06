resource "aws_sns_topic" "sns_topic" {
  name = "${var.prefix}-sns-topic"
  kms_master_key_id  = var.kms_keyid
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.sns_topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        var.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.sns_topic.arn,
    ]

    sid = "__default_statement_ID"
  }
}

resource "aws_sns_topic_subscription" "sns_lambda_target" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = var.lambda_arn
}