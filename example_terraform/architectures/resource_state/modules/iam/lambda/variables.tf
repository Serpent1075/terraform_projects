variable "prefix" {
  description = "The prefix"
  type = string
}

variable "kms_arns" {
  description = "KMS ARN"
  type = list(string)
}