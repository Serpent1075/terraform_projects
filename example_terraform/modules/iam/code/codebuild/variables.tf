variable "account_num" {
  description = "AWS Account Number"
  type = string
}
variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "ap-northeast-2"
}
variable "repository_arn" {
  description = "The ARN of the source repository"
  type = string
}
variable "bucket_name" {
  description = "The name of the bucket"
  type = string
}
variable "codebuild_name"{
  description = "CodeBuild Name"
  type = string
}