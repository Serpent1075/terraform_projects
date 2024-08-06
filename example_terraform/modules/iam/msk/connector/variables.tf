variable "prefix" {
  description = "Prefix"
  type = string
}

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "s3_arn" {
  description = "The S3 ARN for msk"
  type = string
}