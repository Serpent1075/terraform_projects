variable "account_id" {
    description = "Account ID"
    type = string
}

variable "aws_region" {
    description = "AWS Region"
    type = string
}

variable "bucketname" {
    description = "Destination Bucket name"
    type = string
}

variable "stream_name" {
    description = "Stream Name"
    type = string
}

variable "kms_arn" {
    description = "KMS ARN"
    type = string
}