variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "user_tag" {
    type = string
    description = "tag of the resource owner"
}
variable "opensearch_domain" {
    description = "Open Search Domain"
}
variable "acm_arn" {
  type = string
  description = "ACM ARN"
}