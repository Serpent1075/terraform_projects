variable "prefix" {
    description = "Prefix"
    type = string
}
variable "account_id" {
  description = "Account ID"
  type = string
}
variable "lambda_arn" {
  description = "Arn of lambda which subscribe sns topic"
  type = string
}
variable "lambda_name" {
  description = "Name of lambda function"
  type = string
}