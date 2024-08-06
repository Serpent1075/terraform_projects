resource "aws_sns_topic" "slack_sns" {
  name            = "${var.prefix}-WAF-to-Slack"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
}

resource "aws_sns_topic_policy" "slack_sns" {
  arn = aws_sns_topic.slack_sns.arn
  policy = data.aws_iam_policy_document.sns_lambda_policy.json
}


data "aws_iam_policy_document" "sns_lambda_policy" {
  statement {
    effect    = "Allow"
    resources = ["${aws_sns_topic.slack_sns.arn}"]
    actions = [
       "SNS:GetTopicAttributes",
       "SNS:SetTopicAttributes",
       "SNS:AddPermission",
       "SNS:RemovePermission",
       "SNS:DeleteTopic",
       "SNS:Subscribe",
       "SNS:ListSubscriptionsByTopic",
       "SNS:Publish",
       "SNS:Receive"
    ]

    principals {
        type = "AWS"
        identifiers = ["*"]
    }

    condition {
      test = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        "${var.account_id}"
      ]
    }
  }
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.slack_sns.arn
  protocol  = "lambda"
  endpoint  = var.lambda_arn
}

resource "aws_sns_topic_subscription" "rule_update_alarm" {
  topic_arn = "arn:aws:sns:us-east-1:248400274283:aws-managed-waf-rule-notifications"
  protocol  = "lambda"
  endpoint  = var.lambda_arn
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.slack_sns.arn
}