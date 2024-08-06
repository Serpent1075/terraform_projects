variable "prefix" {
    description = "The prefix"
    type = string
}

variable "kms_arns" {
    description = "The kms arns"
    type = list(string)
}