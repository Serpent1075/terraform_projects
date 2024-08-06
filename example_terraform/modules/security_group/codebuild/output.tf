 output "security-group-name" {
   value       = aws_security_group.efs_sg.name
   description = "security group name"
 }
 output "security-group-id" {
  value = aws_security_group.efs_sg.id
  description = "security group id"
 }