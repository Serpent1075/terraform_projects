resource "aws_lambda_function" "resource_state" {

  filename      = "./modules/lambda/resource_state/resource_state.zip"  
  function_name = "${var.prefix}-resource-state"
  description   = "${var.prefix} list up resource state with lambda function"

  role          = var.iam_role
  handler       = var.handler
  runtime       = var.runtime
  timeout  = 900

  memory_size = 1024
  
  

  ephemeral_storage {
    size = 512 # Min 512 MB and the Max 10240 MB
  }


   environment {
    variables = {
      bucketname = "wjcloud-automation"
    }
  }

}


resource "aws_cloudwatch_log_group" "resource_state" {
  name              = "/aws/lambda/${aws_lambda_function.resource_state.function_name}"
  retention_in_days = 14
}


resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.resource_state.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${var.eventbridge_arn}"
}


