 output "security-group-name" {
   value       = aws_security_group.loadbalancer_sg.name
   description = "security group name"
 }
 output "security-group-id" {
  value = aws_security_group.loadbalancer_sg.id
  description = "security group id"
 }