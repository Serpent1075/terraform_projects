variable "prefix" {
  description = "Prefix"
  type = string
}

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}
/*
variable "role_policy_arns" {
  description = "ARN of policy to attach"
  type = list(string)
}*/