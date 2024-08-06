output "lambda-arn" {
  value = aws_lambda_function.sns_lambda.arn
}

output "lambda-name" {
  value = aws_lambda_function.sns_lambda.function_name
}