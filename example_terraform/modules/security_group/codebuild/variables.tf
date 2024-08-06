variable "webapi-sg" {
  description = "Web API Securty Group ID"
  type = string
}
variable "prefix" {
  description = "Prefix of resource"
  type = string
}
variable "nfsport" {
  description = "NFS Port"
  type = number
}
variable "vpc_id" {
  description = "vpc id"
  type = string
}