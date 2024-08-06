variable "multi_region" {
  description = "Multi Region"
  type = bool
}
variable "aws_region" {
  description = "AWS Region"
  type = string
}
variable "account_id" {
  description = "Account ID"
  type = string
}
variable "prefix" {
  description = "KMS Key Name"
  type = string
}
variable "user" {
  description = "user id for aws account"
  type = string
  default = "admin"
}