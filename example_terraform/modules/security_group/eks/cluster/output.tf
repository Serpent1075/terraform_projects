
 output "security-group-id" {
  value = aws_security_group.kuber_sg.id
  description = "security group id"
 }