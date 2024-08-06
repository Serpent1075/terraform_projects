variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "domain_address" {
  description = "Domain Address"
  type = string
}
variable "vpc_id" {
  description = "The vpc id"
  type = string
}

variable "subnets_ids" {
  description = "The Subnet Ids"
  type = list(string)
}

variable "sg" {
  description = "The Security Group of ALB"
  type = list(string)
}
variable "app_port" {
  description = "Port number of the application"
  type = number
}

variable "acm_arn" {
  description = "ACM ARN"
  type = string
}