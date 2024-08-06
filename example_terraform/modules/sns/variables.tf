variable "prefix" {
  description = "KMS Key Name"
  type = string
}

variable "account_id" {
    description = "The account id"
    type = string
}

variable "kms_keyid" {
    description = "KMS Key ID"
    type = string
}

variable "lambda_arn" {
    description = "Target Lambda ARN"
    type = string
}