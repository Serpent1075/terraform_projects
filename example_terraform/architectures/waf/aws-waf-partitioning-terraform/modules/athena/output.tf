output "workgroup_name" {
    value = aws_athena_workgroup.waflogs.name
}

output "athena_database" {
    value = aws_athena_database.waflogs.name
}