variable "prefix" {
    description = "The prefix"
    type = string
}
variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "kms_arn" {
    description = "List of KMS ARNs"
    type = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}