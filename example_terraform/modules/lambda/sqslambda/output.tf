output "lambda_arn" {
    value = aws_lambda_function.sqs_lambda.arn
}

output "lambda_name" {
    value = aws_lambda_function.sqs_lambda.function_name
}