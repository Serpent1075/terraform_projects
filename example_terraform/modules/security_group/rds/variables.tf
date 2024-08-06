variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "vpc_id" {
  description = "vpc id"
  type = string
}
variable "psqlport" {
  description = "Port of resource"
  type = number
}

variable "webapi_sg_id"{
    description = "Web API SG ID"
}

variable "batch_sg_id"{
    description = "Batch SG ID"
}

variable "lambda_sg_id"{
    description = "Lambda SG ID"
}