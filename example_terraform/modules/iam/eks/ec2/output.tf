output "kuber-ec2-role-arn" {
    value = aws_iam_role.kuber_ec2_role.arn
}

output "kuber-ec2-role-profile-name" {
    value = aws_iam_instance_profile.this.name
}