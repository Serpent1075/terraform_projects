variable "prefix" {
    type = string
}
variable "eksregistry_id" {
    type = string
    default = "602401143452"
}
variable "aws_region" {
    type = string
    default = "ap-northeast-2"
}

variable "vpc_id" {
    type = string
}

variable "subnet_ids" {
    type = list(string)
}

variable "kms_arn" {
    type = string
}

variable "cluster_sg" {
    type = string
}