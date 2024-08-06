variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "sufix" {
  description = "Sufix of resource"
  type = string
}
variable "vpc_id" {
  description = "The vpc id"
  type = string
}
variable "app_port" {
  description = "Port number of the application"
  type = number
}

variable "acm_arn" {
  description = "ACM ARN"
  type = string
}

variable "alb_arn"{
    description = "alb arn"
    type = string
}