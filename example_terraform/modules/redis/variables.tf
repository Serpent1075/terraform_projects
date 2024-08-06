variable "prefix" {
  description = "KMS Key Name"
  type = string
}

variable "family" {
  description = "Family"
  type = string
}

variable "node_type" {
    description = "Node Type"
    type = string
}

variable "redisport" {
  description = "Redis Port"
  type = number
}

variable "sg_group_ids" {
  description = "Security Groups IDs"
  type = list(string)
}

variable "subnet_ids" {
    description = "Subnet Ids"
    type = list(string)
}

variable "loggroup-name" {
    description = "Log Group Name"
    type = string
}

variable "maintenance_date" {
    description = "Maintenance Date"
    type = string
}