resource "aws_codecommit_repository" "code-repository" {
  repository_name = "${var.prefix}-codecommit-repository"
  description     = "This is the Web App Repository"
  default_branch = "master"
}