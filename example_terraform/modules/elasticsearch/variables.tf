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
variable "subnet_ids" {
    type = list(string)
    description = "Subnet IDs"
}

variable "domain_name" {
    type = string
    description = "Domain Name"
}

variable "elastic_search_sg_ids" {
    type = list(string)
    description = "Elastic Search Security Group ID"
}