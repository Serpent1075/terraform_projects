variable "prefix" {
    type = string
}
variable "account_id" {
    description = "Account ID"
    type = string
}
variable "username" {
    description = "User Name for aws_auth kuber"
    type = list(string)
}
variable "eksregistry_id" {
    type = string
    default = "602401143452"
}
variable "aws_region" {
    type = string
    default = "ap-northeast-2"
}

variable "cluster_name" {
    type = string
}

variable "vpc_id" {
    type = string
}

variable "subnet_ids" {
    type = list(string)
}

variable "kms_arn" {
    type = string
}

variable "cluster_sg" {
    type = string
}

variable "alb_controller_policy_arn" {
  description = "Alb Controller Policy ARN"
  type = string
}