 output "iam-instance-profile-name" {
   value       = aws_iam_instance_profile.this.name
   description = "IAM role name"
 }

 output "iam-instance-arn" {
  value = aws_iam_role.this.arn
 }