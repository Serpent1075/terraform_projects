variable "prefix" {
    description = "prefix"
    type = string
}

variable "msk_version" {
    description = "msk version"
    type = string
}

variable "bootstrap_tls" {
    description = "bootstrap brokes tls"
    type = string
}

variable "bucket_id" {
    description = "custom plugin bucket id"
    type = string
}
variable "bucket_arn" {
    description = "custom plugin bucket arn"
    type = string
}
variable "subnet_ids" {
    description = "Subnet Identity"
    type = list(string)
}
variable "sg_id" {
    description = "Security Group ID"
    type = string
}
variable "connector_execution_iam_arn" {
    description = "Connector MSK Execution IAM"
    type = string
}