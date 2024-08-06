variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "user_tag" {
    type = string
    description = "tag of the resource owner"
}
variable "stream_name" {
    description = "Stream Name"
    type = string
}
variable "iam_arn" {
    description = "IAM ARN"
    type = string
}
variable "bucket_arn" {
    description = "Bucket ARN"
    type = string
}
/*
variable "kms_arn" {
    description = "KMS ARN"
    type = string
}
*/
variable "cloudwatch_log_group_name" {
    description = "CloudWatch Log Group Name"
    type = string
}
variable "cloudwatch_log_stream_name" {
    description = "CloudWatch Log Stream Name"
    type = string
}
variable "s3_prefix" {
    description = "S3 prefix"
    type = string
}
/*
variable "cluster_arn" {
  description = "OpenSearch Cluster ARN"
  type = string
}
*/
variable "subnet_ids" {
    type = list(string)
    description = "Subnet IDs"
}
/*
variable "opensearch_sg" {
    type = list(string)
    description = "Security Group Ids"
}*/

