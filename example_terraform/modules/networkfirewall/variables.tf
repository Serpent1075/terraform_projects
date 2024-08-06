variable "prefix" {
  description = "Prefix"
  type = string
}

variable "vpc_id" {
  description = "The vpc_id"
  type = string
}

variable "account_id" {
    description = "The account id"
    type = string
}

variable "subnet_ids" {
    description = "The subnet ids"
    type = list(string)
}