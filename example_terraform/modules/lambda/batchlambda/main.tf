data "archive_file" "zip_file_for_lambda" {
  type        = "zip"
  output_path = "./modules/lambda/batchlambda/${var.name}.zip"
  source_dir = "${var.path_source_dir}"
  dynamic "source" {
    for_each = distinct(flatten([
      for blob in var.file_globs :
      fileset("./", blob)
    ]))
    content {
      content = try(
        file("./${source.value}"),
        filebase64("./${source.value}"),
      )
      filename = source.value
    }
  }
}

resource "aws_lambda_function" "batch_lambda" {
  filename      = "./modules/lambda/batchlambda/${var.name}.zip"
  function_name = "${var.prefix}-${var.name}"
  description   = "${var.prefix} ${var.name} lambda function"
  role          = var.iam_role
  handler       = var.handler
  runtime       = var.runtime
  timeout  = 900
  architectures = [var.arch]
  kms_key_arn = var.kms_key_arn

  memory_size = 256
  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }

  depends_on = [
    var.iam_role,
    var.cw_log_group,
  ]
}