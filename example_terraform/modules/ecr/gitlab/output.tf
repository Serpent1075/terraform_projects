output "container-registry-id" {
    description = "Container registry ID"
    value = aws_ecr_repository.container-registry.registry_id
}

output "container-registry-arn" {
    description = "Container registry ARN"
    value = aws_ecr_repository.container-registry.arn
}

output "container-registry-url" {
    description = "Container registry url"
    value = aws_ecr_repository.container-registry.repository_url
}

output "container-registry-name" {
    description = "Container registry Name"
    value = aws_ecr_repository.container-registry.name
}