variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "prefix" {
  description = "Prefix of resource"
  type = string
}

variable "compute_security_group_id" {
  description = "The security group for batch computing"
  type = string
}

variable "batch-iam-arn" {
  description = "The IAM for Operating batch service on behalf of the user"
  type = string
}

variable "subnet_ids" {
  description = "Subnet ID for the batch service"
  type = list(string)
}

variable "app_name" {
  description = "name of app installed in container"
  type = string
}

variable "image_name" {
  description = "name of image in ECR"
  type = string
}

variable "instance_type" {
  description = "Instance type"
  type = string
  default = "c6g.small"
}

variable "vcpu" {
  description = "number of VCPU"
  type = number
  default = "0.25"
}

variable "mem" {
  description = "Amount of memory"
  type = number
  default = "2048"
}

variable "efs_file_system_id" {
  description = "File system ID"
  type = string
}

variable "efsname" {
  description = "File system name"
  type = string
}

variable "sm_prefix_arn" {
  description = "Secret Manager Prefix ARN"
  type = string
}

variable "sm_redis_arn" {
  description = "Secret Manager Redis ARN"
  type = string
}

variable "sm_rds_arn" {
  description = "Secret Manager RDS ARN"
  type = string
}

variable "sm_pw_arn" {
  description = "Secret Manager Password ARN"
  type = string
}

variable "sm_mongo_arn" {
  description = "Secret Manager MongoURL ARN"
  type = string
}
