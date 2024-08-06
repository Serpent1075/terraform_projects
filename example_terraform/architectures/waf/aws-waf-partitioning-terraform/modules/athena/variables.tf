variable "prefix" {
    description = "The prefix" 
    type = string
}
variable "aws_region" {
    description = "AWS Region"
    type = string
}

variable "s3_bucket_id" {
    type = string
    description = "AWS WAF Log directory"
}
variable "s3_bucket_name" {
    type = string
    description = "AWS WAF Log directory"
}

variable "account_id" {
    type = string
    description = "Account ID"
}