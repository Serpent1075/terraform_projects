output "arn" {
  value = "${aws_lambda_function.lambda.arn}:${aws_lambda_function.lambda.version}"
}

output "function_arn" {
  value = aws_lambda_function.lambda.arn
}
output "function_name" {
  value = var.name
}
