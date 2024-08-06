variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "ap-northeast-2"
}

variable "prefix" {
  type = string
  default = "prefix for the policy"
}

variable "kms_arn" {
  type = string
  description = "The kms arn for the policy"
}