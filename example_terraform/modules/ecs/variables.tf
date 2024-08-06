variable "prefix" {
    description = "Prefix"
    type = string
}
variable "aws_region" {
  description = "The AWS region"
  type = string
}
variable "imagename" {
    description = "Image Name"
    type = string
}
variable "lb_tg_arn" {
    description = "Load balancer Target Group ARN"
    type = string
}

variable "subnets_ids" {
    description = "Subnet IDs"
    type = list(string)
}
variable "sg" {
    description = "Security Groups"
    type = list(string)
}
variable "iam_arn" {
    description = "IAM ARN"
    type = string
}

variable "task_execution_arn" {
    description = "Task Execution IAM ARN"
    type = string
}

variable "kms_arn"{
    description = "KMS ARN"
    type = string
}

variable "loggroup_name" {
    description = "Log group name"
    type = string
}

variable "image_url" {
    description = "Image URL"
    type = string
}

variable "file_system_id" {
    description = "File system ID"
    type = string
}

variable "file_system_access_point" {
    description = "File system access point ID"
    type = string
}