variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "user_tag" {
    type = string
    description = "tag of the resource owner"
}

variable "s3_id" {
    type = string
    description = "s3 id"
}
variable "vpc_id" {
    type = string
    description = "VPC ID"
}

variable "subnet_ids" {
    type = list(string)
    description = "subnet ids"
}

variable "sg" {
    type = list(string)
    description = "security group ids"
}

variable "target_type" {
    type = string
    description = "Target Type"
}
variable "protocol" {
    type = string
    description = "Target Type"
}
variable "resource_ip" {
    type = string
    description = "Target IP"
}