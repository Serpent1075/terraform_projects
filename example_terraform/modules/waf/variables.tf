variable "prefix" {
    description = "Prefix"
    type = string
}

variable "countrycode" {
    description = "Country code"
    type = list(string)
    default = ["US"]
}

variable "alb_arn" {
    description = "Prod ALB ARN"
    type = string
}
variable "kms_arn" {
    description = "KMS ARN"
    type = string
}
/*
variable "log_bucket_arn" {
    description = "Bucket ARN"
    type = string
}

variable "kinesis_arn" {
    description = "Kinesis ARN"
    type = string
}*/