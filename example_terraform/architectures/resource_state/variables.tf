variable "access_key"{
  description = "The access key in which all resources will be created"
  type = string
  sensitive = true        //민감정보일 경우 활성화
}
variable "secret_key" {
  description = "The secret key in which all resources will be created"
  type = string
  sensitive = true        //민감정보일 경우 활성화
}

variable "prefix" {
  description = "prefix of resource name"
  type = string
  default = "wjcloud-tf"
}

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "ap-northeast-2"
}