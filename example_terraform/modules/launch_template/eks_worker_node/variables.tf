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
variable "sg-ids"{
  description = "security group name"
  type = list(string)
}
variable "node_subnet_id" {
  description = "launch temblate eks node subnet id"
  type = string
}
variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}
variable "cluster_name" {
  description = "Cluster Name"
  type = string
}