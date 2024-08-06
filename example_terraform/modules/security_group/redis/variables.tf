variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "vpc_id" {
  description = "vpc id"
  type = string
}
variable "webapi_sg_id"{
    description = "Web API SG ID"
    type = string
}

variable "batch_sg_id"{
    description = "batch SG ID"
    type = string
}
variable "lambda_sg_id"{
    description = "batch SG ID"
    type = string
}
variable "redisport" {
  description = "Redis port"
  type = number
}