variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "instance_type" {
  description = "instance type"
  type = string
}
variable "image_id"{
  description = "AWS Image Id"
  type = string
}
variable "key_name"{
  description = "key name"
  type = string
}
variable "iam-name"{
  description = "iam name"
  type = string
}
variable "sg-id"{
  description = "security group name"
  type = string
}
variable "webapi-subnet-id" {
  description = "launch temblate webapi subnet id"
  type = string
}
variable "ps-cw-config"{
  description = "Parameter Store Cloud Watch Config"
  type = string
}
variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}