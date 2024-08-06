provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

data "archive_file" "zip_file_for_lambda" {
  type        = "zip"
  output_path = "./modules/lambda/lambdaedge/${var.name}.zip"
  source_dir = "${var.path_source_dir}${var.name}"
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

resource "aws_s3_object" "lambdaedge" {
  provider = aws.virginia
  bucket = var.s3_artifact_bucket
  key    = "lambdaedge/${var.name}.zip"
  source = data.archive_file.zip_file_for_lambda.output_path
  kms_key_id = var.kms_replica_arn
  tags   = var.tags
}

resource "aws_lambda_function" "lambda" {
  provider = aws.virginia
  function_name = "${var.prefix}-${var.name}"
  description   = "${var.prefix} ${var.name} lambda function"

  # Find the file from S3
  s3_bucket        = aws_s3_object.lambdaedge.bucket
  s3_key = aws_s3_object.lambdaedge.key
  s3_object_version = aws_s3_object.lambdaedge.version_id
  source_code_hash  = filebase64sha256(data.archive_file.zip_file_for_lambda.output_path)

  publish = true
  handler = var.handler
  runtime = var.runtime
  role    = var.iam_arn
  tags    = var.tags
  memory_size = var.mem_size
  kms_key_arn = var.kms_replica_arn
  ephemeral_storage {
    size = var.ephemeral_storage_size # Min 512 MB and the Max 10240 MB
  }
}




