variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}
variable "launch_template_id" {
  description = "The AWS region in which all resources will be created"
  type        = string
}
variable "prefix" {
  description = "The AWS prefix"
  type = string
}
variable "zone_id" {
  description = "The subnet zone ids"
  type = list(string)
}

variable "alb_targetgroup_arn" {
  description = "Application Load Balancer Target Group ARN"
  type        = string
}