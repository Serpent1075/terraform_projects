variable "vpc_id" {
  description = "vpc id"
  type = string
}
variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "webapi_port" {
  description = "webapi port"
  type = number
}
variable "ssh_port" {
  description = "ssh port"
  type = number
}
variable "source_cidr_blocks_for_all_outbound_ipv4"{
  description = "source cidr block for all outbound traffic of ipv4"
  type = list(string)
}
variable "source_cidr_blocks_for_all_outbound_ipv6"{
  description = "source cidr block for all outbound traffic of ipv6"
  type = list(string)
}
variable "source_cidr_blocks_for_ssh_ipv4"{
  description = "source cidr block for ssh of ipv4"
  type = list(string)
}
variable "source_cidr_blocks_for_ssh_ipv6"{
  description = "source cidr block for ssh of ipv6"
  type = list(string)
}
variable "source_cidr_blocks_for_web_ipv4"{
  description = "source cidr block for web of ipv4"
  type = list(string)
}
variable "source_cidr_blocks_for_web_ipv6"{
  description = "source cidr block for web of ipv6"
  type = list(string)
}
