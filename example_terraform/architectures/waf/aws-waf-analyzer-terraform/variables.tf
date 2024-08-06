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
variable "prefix" {          // 리소스 접두사 (고객사 서비스 명칭으로 수정 필요)
  description = "prefix of resource name"
  type = string
  default = "waf-tf"
}
variable "aws_region" {               //구축할 리전
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "ap-northeast-2"
}
variable "user_tag" {             //리소스 생성자 이름
    description = "default tag"
    type = string
    default = "오정환"
}