variable "prefix" {
    description = "The prefix" 
    type = string
}

variable "bucket_regional_domain_name" {
    description = "Bucket regional domain name"
    type = string
}

variable "log_bucket_name" {
    description = "Log bucket name"
    type = string
}

variable "log_bucket_prefix" {
    description = "Log bucket prefix"
    type = string
}

variable "list_alias_domain" {
    description = "List Alias Domain"
    type = list(string)
}
variable "domain_address" {
    description = "Domain Address"
    type = string
}

variable "origin_bucket_name" {
    description = "Origin Bucket Name"
    type = string
}

variable "origin_bucket_id" {
    description = "Origin Bucket ID"
    type = string
}

variable "origin_bucket_arn" {
    description = "Origin Bucket ARN"
    type = string
}

variable "ec2_iam_arn" {
    description = "EC2 IAM ARN"
    type = string
}

variable "propic_origin_path" {
    description = "Origin Path"
    type = string
}

variable "terms_origin_path" {
    description = "Origin Path"
    type = string
}

variable "lambda_iam_arn" {
    type = string
}

variable "viewer_req_lambda_arn" {
    description = "Viewer Request Lambda@Edge function arn"
    type = string
}

variable "origin_resp_lambda_arn" {
    description = "Origin Response Lambda@Edge function arn"
    type = string
}
