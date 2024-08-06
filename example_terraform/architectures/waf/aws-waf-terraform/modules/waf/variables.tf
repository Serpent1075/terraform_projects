variable "prefix" {
    description = "Prefix"
    type = string
}
variable "user_tag" {
    type = string
    description = "tag of the resource owner"
}

variable "countrycode" {
    description = "Country code"
    type = list(string)
    default = ["US"]
}
variable "kinesis_arn" {
    description = "Kinesis ARN"
    type = string
}
/*
variable "kms_arn" {
    description = "KMS ARN"
    type = string
}
*/

