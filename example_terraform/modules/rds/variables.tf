variable "prefix" {
  description = "KMS Key Name"
  type = string
}

variable "subnet_ids" {
    description = "Subnet Ids"
    type = list(string)
}

variable "engine" {
    description = "Engine"
    type = string
}

variable "psqlversion" {
    description = "Postgresql Version"
    type = string
}
variable "family" {
    description = "Postgresql DB Prameter Group Family"
    type = string
}
variable "database_name"{
    description = "Database Name"
    type = string
}
variable "adminname" {
    description = "Database admin name"
    type = string
}

variable "password" {
    description = "Database password"
    type = string
}
variable "psqlport" {
    description = "Database Port"
    type = number
}

variable "iam_roles"{
    description = "Database IAM Role"
    type = list(string)
}

variable "reader_instance_class" {
    description = "Database Reader Instance Class"
    type = string
}

variable "writer_instance_class" {
    description = "Database Writer Instance Class"
    type = string
}

variable "kms_arn" {
    description = "Database KMS ARN"
    type = string
}

variable "vpc_security_group_ids" {
    description = "Database VPC Security Group"
    type = list(string)
}

variable "maintenance_date" {
    description = "Maintenance Date"
    type = string
}