variable "prefix" {
  description = "The prefix"
  type = string
}

variable "s3_arn" {
  description = "arn of s3 that store aws waf logs and athena query result"
  type = string
}