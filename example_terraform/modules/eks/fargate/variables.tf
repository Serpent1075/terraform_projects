variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "vpc_id" {
  description = "VPC ID of resource"
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
variable "kms_arn" {
  description = "KMS ARN"
  type = string
}
variable "cluster_sg" {
  description = "Cluster Security Group"
  type = string
}
variable "node_sg" {
  description = "Node Security Group"
  type = string
}
variable "cluster_role_arn" {
  description = "EKS Cluster Role ARN"
  type = string
}

variable "fargate_execution_role_arn" {
  description = "Fargate Execution Role ARN"
  type = string
}

variable "alb_controller_policy_arn" {
  description = "Alb Controller Policy ARN"
  type = string
}