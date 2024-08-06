#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_managed_user_pool_client


resource "aws_cognito_user_pool" "opensearch" {
  name = "${var.prefix}-OpenSearch-User-Pool"
}

resource "aws_cognito_identity_pool" "opensearch" {
  identity_pool_name = "${var.prefix}-Identity-Pool"

  lifecycle {
    ignore_changes = [cognito_identity_providers]
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${var.prefix}-userpool-client-opensearch"

  user_pool_id = aws_cognito_user_pool.opensearch.id
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "${var.prefix}-userpool-domain"

  user_pool_id = aws_cognito_user_pool.opensearch.id
}
