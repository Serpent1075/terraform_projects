variable "prefix" {
  description = "Prefix"
  type = string
}

variable "name" {
  description = "Name of the Lambda@Edge Function"
  type = string
}

variable "path_source_dir" {
  description = "Path of the code directory in local computer" 
  type = string
}

variable s3_artifact_bucket {
  description = "Name of the S3 bucket to upload versioned artifacts to"
  type = string
}

variable iam_arn {
  description = "ARN of the IAM"
  type = string
}

variable "kms_replica_arn" {
  description = "ARN of the KMS"
  type = string
}

variable tags {
  type        = map(string)
  description = "Tags to apply to all resources that support them"
  default     = {}
}


variable file_globs {
  type        = list(string)
  default     = ["index.js", "node_modules/*", "package-lock.json", "package.json"]
  description = "list of files or globs that you want included from the lambda_code_source_dir"
}

variable runtime {
  description = "The runtime of the lambda function"
  default     = "nodejs16.x"
}

variable handler {
  description = "The path to the main method that should handle the incoming requests"
  default     = "index.handler"
}

variable "mem_size" {
  description = "The size of memory used by the lambda function"
  type = number
}

variable "ephemeral_storage_size" {
  description = "The size of ephemeral storage size used by the lambda function"
  type = number
}