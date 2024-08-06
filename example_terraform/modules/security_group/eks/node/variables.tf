variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "vpc_id" {
  description = "vpc id"
  type = string
}
variable "cluster_sg_id" {
  description = "Cluster Security Group ID"
  type = string
}
variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type = string
}
/*
variable "cluster_name" {
  description = "Cluster Name"
  type = string
}
variable "node_group_name" {
  description = "Node Group Name"
  type = string
}
variable "launch_template_id" {
  description = "Launch Template ID"
  type = string
}
variable "launch_template_version" {
  description = "version of template"
  type = number
}

variable "autoscaling_group_name" {
  description = "Launch Template ID"
  type = string
}*/