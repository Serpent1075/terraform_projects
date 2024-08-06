provider "aws" {
  alias = "current_region"
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "constant-secret-manager" {
  provider = aws.current_region
  name                = "${var.prefix}/${var.secretname}/"
  kms_key_id = var.kms_arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "constant-sversion" {
  secret_id = aws_secretsmanager_secret.constant-secret-manager.id
  secret_string = jsonencode(var.secret_value)
}

