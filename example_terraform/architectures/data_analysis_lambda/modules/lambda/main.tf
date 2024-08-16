resource "aws_lambda_function" "sns_lambda" {

  filename      = "lambda_function.zip"  
  function_name = "${var.prefix}-WAF-SNS-to-Slack"
  description   = "${var.prefix} waf event send to slack via sns with lambda function"

  role          = var.iam_role
  handler       = var.handler
  runtime       = var.runtime
  timeout  = 900

  source_code_hash = data.archive_file.lambda.output_base64sha256
  memory_size = 1024
  
  

  ephemeral_storage {
    size = 512 # Min 512 MB and the Max 10240 MB
  }

   environment {
    variables = {
      slackChannel = "aws-waf"
      clientName = var.client_name
    }
  }
}


## 람다에 삽입할 코드이며 최상위 main.tf파일 기준으로부터의 경로를 입력
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "./modules/lambda/lambda_function.py"
  output_path = "./lambda_function.zip"
}

resource "aws_cloudwatch_log_group" "sns_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.sns_lambda.function_name}"
  retention_in_days = 14
}
