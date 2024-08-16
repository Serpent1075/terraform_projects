variable "prefix" {
    description = "Prefix"
    type = string
}
variable "account_id" {
    description = "Account ID"
    type = string
}

variable "peer_vpc_id" {
    description = "Peering VPC ID"
    type = string
}
variable "vpc_id" {
    description = "VPC ID"
    type = string
}
variable "host_route_table_id" {
    description = "Host Route Table ID"
    type = string
}
variable "host_cidr_block" {
    description = "Host CIDR Block"
    type = string
}
variable "peer_route_table_id" {
    description = "Peer Route Table ID"
    type = string
}
variable "peer_cidr_block" {
    description = "Peer CIDR Block"
    type = string
}