variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "user_tag" {
    type = string
    description = "tag of the resource owner"
}
variable "aws_region" {
    type = string
    description = "AWS Region"
}
variable "sns_arn" {
  type = string
  description = "Arn of SNS to send alarm from cloudwatch"
}