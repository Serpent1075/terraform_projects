variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "iam_arn" {
    description = "ARN of IAM role for Code Build"
    type = string
}
variable "kms_arn" {
    description = "ARN of KMS role for Code Build"
    type = string
}
variable "source_type" {
    description = "Type of source repository"
    type = string
}
variable "source_location" {
    description = "Source repository location for Code Build"
    type = string
}
variable "codebuildbucket-name" {
    description = "Bucket Name For Code Build"
    type = string
}
variable "buildspec" {
    description = "Build Specification for Code Build"
    type = string
}
variable "github_token"{
    description = "Github Token for Code Build"
    type = string
}
variable "bucket_name"{
    description = "Bucket Name for Code Build"
    type = string
}
variable "s3_path"{
    description = "s3 path for Code Build"
    type = string
}
variable "artifact_name" {
    description = "Artifact Name for Code Build"
    type = string
}
variable "architecture" {
    description = "Architecture for Code Build"
    type = string
}
/*
variable "vpc_id"{
    description = "VPC ID for Code Build"
    type = string
}
variable "subnets_id" {
    description = "Subnets ID for Code Build"
    type = list(string)
}
variable "sg_ids" {
    description = "Security Group ID for Code Build"
    type = list(string)
}
*/