
 output "security-group-id" {
  value = aws_security_group.endpoint_sg.id
  description = "security group id"
 }