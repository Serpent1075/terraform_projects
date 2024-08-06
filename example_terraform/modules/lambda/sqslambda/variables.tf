variable "prefix" {
  description = "The prefix"
  type = string
}

variable "name" {
  description = "Name of the lambda function"
  type = string
}

variable "iam_role" {
    description = "The IAM Roles"
    type = string
}

variable "handler" {
    description = "Handler of the lambda function"
    type = string
}

variable "runtime" {
    description = "Runtime"
    type = string
}

variable "arch" {
    description = "Architecture"
    type = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN"
  type = string
}
variable file_globs {
  type        = list(string)
  description = "list of files or globs that you want included from the lambda_code_source_dir"
}

variable "path_source_dir" {
  description = "Path of the code directory in local computer" 
  type = string
}

variable s3_artifact_bucket {
  description = "Name of the S3 bucket to upload versioned artifacts to"
  type = string
}

variable tags {
  type        = map(string)
  description = "Tags to apply to all resources that support them"
  default     = {}
}


