variable "prefix" {
  description = "The prefix"
  type = string
}

variable "iam_role" {
    description = "The IAM Roles"
    type = string
}

variable "runtime" {
    description = "Runtime"
    type = string
}

variable "handler" {
    description = "Runtime"
    type = string
}

variable "eventbridge_arn" {
    description = "ARN of eventbridge that triggers lambda"
    type = string
}

variable "bucket_name" {
    description = "athena waf log workgroup name"
    type = string
}