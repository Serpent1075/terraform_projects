variable "prefix" {
  description = "Prefix of resource"
  type = string
}

variable "kms_arn" {
    description = "ARN of KMS role for Code Build"
    type = string
}