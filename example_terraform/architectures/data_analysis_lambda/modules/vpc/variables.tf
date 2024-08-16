variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "az_a" {
  type = string
}
variable "az_c" {
  type = string
}

variable "cidr_vpc" {
  type = string
}

variable "cidr_pub_a" {
  type = string
  description = "Public Subnet Primary"
}

variable "cidr_pub_c" {
  type = string
  description = "Public Subnet Secondary"
}

variable "cidr_pri_a" {
  type = string
  description = "Private Subnet Primary"
}

variable "cidr_pri_c" {
  type = string
  description = "Private Subnet Secondary"
}

/*
variable "pub_nat_eip_private" {
  type = string
  description = "NAT EIP"
}*/