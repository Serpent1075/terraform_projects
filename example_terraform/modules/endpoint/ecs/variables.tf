variable "prefix" {
  description = "The prefix"
  type = string
}
variable "aws_region" {
  description = "The AWS region"
  type = string
}

variable "vpc_id" {
  description = "The vpc_id"
  type = string
}

variable "subnet_ids" {
  description = "The subnet IDs"
  type = list(string)
}

variable "endpoint_sg_id" {
  description = "The Endpoint's Security Group ID"
  type = string
}

variable "ecs_iam_arn" {
  description = "The Endpoint's ECS instance arn"
  type = string
}

variable "route_table_id" {
  description = "The Route Table ID to be associated"
}
