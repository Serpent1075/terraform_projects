variable "prefix" {
  description = "Prefix of resource"
  type = string
}

variable "cluster_name" {
  description = "Cluster Name"
  type = string
}
variable "subnet_ids" {
    description = "Subnet IDs of resource"
    type = list(string)
}
/*
variable "kms_arn" {
  description = "KMS ARN"
  type = string
}
*/
variable "cluster_sg" {
  description = "Cluster Security Group"
  type = string
}
variable "ec2_ssh_key" {
  description = "EC2 SSH Key"
  type = string
}
variable "cluster_role_arn" {
  description = "EKS Cluster Role ARN"
  type = string
}

variable "ec2_role_arn" {
    description = "Work Node Role"
    type = string
}

variable "alb_controller_policy_arn" {
  description = "Alb Controller Policy ARN"
  type = string
}

variable "lt_id" {
  description = "Launch Template ID"
  type = string
}