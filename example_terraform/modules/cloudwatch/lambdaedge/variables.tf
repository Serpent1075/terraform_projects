variable "cloudwatch_log_groups_kms_arn" {
    type = string
    description = "KMS usage for Cloudwatch Log Group"
}

variable "prefix" {
    type = string
    description = "Prefix"
}

variable "name" {
    type = string
    description = "Name of the log group"
}