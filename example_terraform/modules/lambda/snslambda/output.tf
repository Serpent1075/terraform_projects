output "lambda_arn" {
    value = aws_lambda_function.sns_lambda.arn
}

output "lambda_name" {
    value = aws_lambda_function.sns_lambda.function_name
}

