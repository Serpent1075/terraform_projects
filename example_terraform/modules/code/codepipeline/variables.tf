variable "prefix" {
  description = "Prefix of resource"
  type = string
}

variable "aws_region" {
    description = "AWS Region"
    type = string
}

variable "iam_arn" {
    description = "IAM arn for Code Pipeline"
    type = string
}

variable "code_bucket" {
    description = "Code bucket for Code Pipeline"
    type = string
}

variable "kms_arn"{
    description = "KMS ARN for Code Pipeline"
    type = string
}

variable "codecommit_id" {
    description = "Code Commit ID for Code Pipeline"
    type = string
}

variable "codebuild_name" {
    description = "Code Build Name for Code Pipeline"
    type = string
}

variable "codedeploy_app_name" {
    description = "Code Deploy App Name for Code Pipeline"
    type = string
}

variable "codedeploy_deploy_group_name" {
    description = "Code Deploy Deploy Group Name for Code Pipeline"
    type = string
}