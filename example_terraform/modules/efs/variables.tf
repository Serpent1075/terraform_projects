variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "pri_sub_a_id" {
  description = "Private Subnet A ID"
  type = string
}

variable "pri_sub_b_id" {
  description = "Private Subnet B ID"
  type = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN"
  type = string
}
variable "efs-sg" {
  description = "efs-sg"
  type = list(string)
}