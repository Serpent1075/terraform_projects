output "lambda_arn" {
    value = aws_lambda_function.partitioning.arn
}

output "lambda_name" {
    value = aws_lambda_function.partitioning.function_name
}

