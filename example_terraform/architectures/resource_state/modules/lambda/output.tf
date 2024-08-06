output "lambda_arn" {
    value = aws_lambda_function.resource_state.arn
}

output "lambda_name" {
    value = aws_lambda_function.resource_state.function_name
}

