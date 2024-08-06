 output "security-group-name" {
   value       = aws_security_group.batch_sg.name
   description = "security group name"
 }
 
 output "security-group-id" {
  value = aws_security_group.batch_sg.id
  description = "security group id"
 }