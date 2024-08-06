resource "aws_ecr_repository" "container-registry" {
  name                 = "${var.prefix}-webapi"
  image_tag_mutability = "MUTABLE"
  

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key = var.kms_arn
  }
}