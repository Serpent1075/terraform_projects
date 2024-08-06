variable "prefix" {
  description = "Prefix of resource"
  type = string
}

variable "gitlab_authorizer_invoke_arn" {
  description = "Invoke Lambda ARN"
  type = string
}

variable "gitlab_webhook_lambda_invoke_arn" {
  description = "Invoke Lambda ARN"
  type = string
}