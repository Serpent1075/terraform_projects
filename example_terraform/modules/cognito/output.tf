output "user_pool_id" {
  value = aws_cognito_user_pool.opensearch.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.opensearch.id
}