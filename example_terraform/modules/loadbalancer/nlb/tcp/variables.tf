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

variable "subnets_ids" {
  description = "The Subnet Ids"
  type = list(string)
}

variable "sg" {
  description = "The Security Group of ALB"
  type = list(string)
}
variable "listener_https_port" {
  description = "Port number of the application"
  type = number
}
variable "listener_http_port" {
  description = "Port number of the application"
  type = number
}
variable "https_app_port" {
  description = "Port number of the application"
  type = number
}

variable "http_app_port" {
  description = "Port number of the application"
  type = number
}