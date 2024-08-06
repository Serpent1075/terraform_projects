variable "prefix" {
    description = "prefix"
    type = string
}

variable "msk_version" {
    description = "msk version"
    type = string
}

variable "firehose_name" {
    description = "firehose name"
    type = string
}

variable "log_group" {
    description = "log group"
    type = string
}

variable "bucket_id" {
    description = "bucket id"
    type = string
}

variable "subnet_ids" {
    description = "Subnet Identity"
    type = list(string)
}
variable "sg_id" {
    description = "Security Group ID"
    type = string
}
variable "kms_key_arn" {
    description = "KMS Key ARN"
    type = string
}

variable "secret_arn" {
    description = "secret manager arn"
    type = string
}
