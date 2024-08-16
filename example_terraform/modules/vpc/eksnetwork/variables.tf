variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "cluster_name" {
    description = "Cluster Name"
    type = string
}
variable "vpc_id" {
    description = "VPC ID"
    type = string
}
variable "cidr_kuber_pub_a" {
    description = "CIDR Kubernetes Public A"
    type = string
}
variable "cidr_kuber_pub_b" {
    description = "CIDR Kubernetes Public B"
    type = string
}
variable "cidr_kuber_pub_c" {
    description = "CIDR Kubernetes Public C"
    type = string
}
variable "cidr_kuber_pri_a" {
    description = "CIDR Kubernetes Private A"
    type = string
}
variable "cidr_kuber_pri_b" {
    description = "CIDR Kubernetes Private B"
    type = string
}
variable "cidr_kuber_pri_c" {
    description = "CIDR Kubernetes Private C"
    type = string
}
variable "az_a" {
    description = "Availability Zone A"
    type = string
}
variable "az_b" {
    description = "Availability Zone B"
    type = string
}
variable "az_c" {
    description = "Availability Zone C"
    type = string
}
variable "pub_kuber_nat_eip_private" {
    description = "Kubernetes Nat Private IP"
    type = string
}
variable "igw_id" {
    description = "Internet Gateway ID"
    type = string
}