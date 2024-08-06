output "file-system-id" {
    value = aws_efs_file_system.efs.id
}

output "efs_access_point" {
    value = aws_efs_access_point.efs_access_point.id
}