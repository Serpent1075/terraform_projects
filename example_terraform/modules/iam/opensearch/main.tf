resource "aws_iam_role" "opensearch_cognito" {
  name               = "${var.prefix}-OpenSearch-Cognito-Role"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.opensearch_cognito.json
}

data "aws_iam_policy_document" "opensearch_cognito" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "es.${data.aws_partition.current.dns_suffix}",
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "opensearch_cognito" {
  role       = aws_iam_role.opensearch_cognito.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonESCognitoAccess"
}

data "aws_partition" "current" {}