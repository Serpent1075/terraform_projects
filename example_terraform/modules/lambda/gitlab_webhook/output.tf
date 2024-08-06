output "arn" {
  value = "${aws_lambda_function.gitlab_webhook.arn}:${aws_lambda_function.gitlab_webhook.version}"
}

output "function_arn" {
  value = aws_lambda_function.gitlab_webhook.arn
}
output "function_name" {
  value = var.name
}
output "invoke_arn" {
  value = aws_lambda_function.gitlab_webhook.invoke_arn
}