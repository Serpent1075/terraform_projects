variable "prefix" {
    description = "The prefix" 
    type = string
}
variable "user_tag" {
    type = string
    description = "tag of the resource owner"
}
variable "kinesis_name" {
    description = "Name of the lambda function"
    type = string
}