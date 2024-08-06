provider "aws" {
  alias  = "primary"
  region = var.aws_region
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_kms_key" "kms-key" {
  provider = aws.primary
  description             = "KMS key"
  deletion_window_in_days = 10
  key_usage = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region = var.multi_region
  policy      = "${data.template_file.kms_policy.rendered}"
}

resource "aws_kms_replica_key" "replica" {
  description             = "Multi-Region replica key"
  deletion_window_in_days = 10
  primary_key_arn         = aws_kms_key.kms-key.arn
}

resource "aws_kms_alias" "alias" {
  name          = "alias/${var.prefix}-kms"
  target_key_id = "${aws_kms_key.kms-key.key_id}"
}

data "template_file" "kms_policy" {
  template = "${file("${path.module}/kms_policy.json.tpl")}"

  vars = {
    account_id = "${var.account_id}"
    aws_region = "${var.aws_region}"
  }
}

