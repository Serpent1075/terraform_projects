variable "aws_region" {
  description = "AWS Region"
  type = string
}

variable "prefix" {
  description = "KMS Key Name"
  type = string
}

variable "kms_arn" {
    description = "ARN of KMS role for Code Build"
    type = string
}
variable "secretname" {
  description = "Secret Name"
  type = string
}
variable "secret_value" {
  description = "Secret value"
  type = map(string)
}
