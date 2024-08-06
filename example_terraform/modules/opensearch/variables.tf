variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "user_tag" {
    type = string
    description = "tag of the resource owner"
}
variable "account_id" {
    description = "Account ID"
    type = string
}
variable "region" {
    description = "AWS Region"
    type = string
}

variable "domain" {
    type = string
    description = "OpenSearch Domain"
}
variable "subnet_ids" {
    type = list(string)
    description = "Subnet IDs"
}
/*
variable "opensearch_sg" {
    type = list(string)
    description = "Security Group Ids"
}
*/
variable "acm_arn" {
    type = string
    description = "ACM ARN"
}
variable "domain_address" {
    type = string
    description = "Custom Domain Address"
}

/*
variable "user_pool_id" {
    type = string
    description = "User Pool ID"
}
variable "identity_pool_id" {
    type = string
    description = "Identity Pool ID"
}
variable "cognito_iam_arn" {
    type = string
    description = "Cognito IAM ARN"
}
*/