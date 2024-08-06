variable "prefix" {
  description = "The prefix"
  type = string
}

variable "name" {
  description = "Name of the lambda function"
  type = string
}

variable "iam_role" {
    description = "The IAM Roles"
    type = string
}

variable "vpc_subnet_ids" {
    description = "The VPC Subnet IDs"
    type = list(string)
}

variable "vpc_security_group_ids" {
    description = "The VPC Security Group IDs"
    type = list(string)
}

variable "handler" {
    description = "Handler of the lambda function"
    type = string
}

variable "runtime" {
    description = "Runtime"
    type = string
}

variable "arch" {
    description = "Architecture"
    type = string
}

variable file_globs {
  type        = list(string)
  default     = ["batchlambda"]
  description = "list of files or globs that you want included from the lambda_code_source_dir"
}

variable "path_source_dir" {
  description = "Path of the code directory in local computer" 
  type = string
}

variable "cw_log_group" {
    description = "Cloudwatch Log Group"
    type = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN"
  type = string
}