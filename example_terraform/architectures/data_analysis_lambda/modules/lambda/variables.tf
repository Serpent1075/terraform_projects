variable "prefix" {
  description = "The prefix"
  type = string
}

variable "iam_role" {
    description = "The IAM Roles"
    type = string
}

variable "runtime" {
    description = "Runtime"
    type = string
}

variable "handler" {
    description = "Runtime"
    type = string
}

variable "client_name" {
  description = "Client Name"
  type = string
}
