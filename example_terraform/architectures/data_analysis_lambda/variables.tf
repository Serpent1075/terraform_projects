
variable "prefix" {
  description = "prefix of resource name"
  type = string
  default = "jhoh-tf"
}

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "ap-northeast-2"
}
variable "access_key"{
  description = "The access key in which all resources will be created"
  type = string
  sensitive = true
}
variable "secret_key" {
  description = "The secret key in which all resources will be created"
  type = string
  sensitive = true
}

variable "az_a" {
  type = string
  default = "ap-northeast-2a"
}

variable "az_c" {
  type = string
  default = "ap-northeast-2c"
}

variable "cidr_vpc" {
  type = string
  default = "172.20.0.0/16"
}

variable "cidr_pub_a" {
  type = string
  default = "172.20.4.0/22"
}
variable "cidr_pub_c" {
  type = string
  default = "172.20.8.0/22"
}
variable "cidr_pri_a" {
  type = string
  default = "172.20.12.0/22"
}
variable "cidr_pri_c" {
  type = string
  default = "172.20.16.0/22"
}

variable "pub_nat_eip_private" {
  type = string
  default = "172.20.4.5"
}