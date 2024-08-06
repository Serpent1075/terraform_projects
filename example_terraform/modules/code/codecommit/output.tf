output "code-repository-id" {
    value = aws_codecommit_repository.code-repository.id
}

output "code-repository-clone-url-http" {
    value = aws_codecommit_repository.code-repository.clone_url_http
}

output "code-repository-arn" {
    value = aws_codecommit_repository.code-repository.arn
}
