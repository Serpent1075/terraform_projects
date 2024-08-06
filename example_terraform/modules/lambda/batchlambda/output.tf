output "lambda_arn" {
    value = aws_lambda_function.batch_lambda.arn
}

output "lambda_name" {
    value = aws_lambda_function.batch_lambda.function_name
}