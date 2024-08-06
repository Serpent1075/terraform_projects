output "secret_arn" {
    value = aws_secretsmanager_secret.constant-secret-manager.arn
}

output "secret_version" {
    value = aws_secretsmanager_secret_version.constant-sversion.id
}