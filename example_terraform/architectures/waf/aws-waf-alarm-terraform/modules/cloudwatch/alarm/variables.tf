variable "prefix" {
  description = "Prefix of resource"
  type = string
}

variable "aws_region" {
    type = string
    description = "AWS Region"
}
variable "sns_arn" {
  type = string
  description = "Arn of SNS to send alarm from cloudwatch"
}