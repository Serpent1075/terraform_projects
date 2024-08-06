data "archive_file" "zip_file_for_lambda" {
  type        = "zip"
  output_path = "./modules/lambda/sqslambda/${var.name}.zip"
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

resource "aws_s3_object" "code_stored_in_s3" {
  bucket = var.s3_artifact_bucket
  key    = "${var.name}/${var.name}.zip"
  source = data.archive_file.zip_file_for_lambda.output_path
  kms_key_id = var.kms_key_arn
  tags   = var.tags
}


resource "aws_lambda_function" "sqs_lambda" {
  
  function_name = "${var.prefix}-${var.name}"
  description   = "${var.prefix} ${var.name} lambda function"

  s3_bucket        = aws_s3_object.code_stored_in_s3.bucket
  s3_key = aws_s3_object.code_stored_in_s3.key
  s3_object_version = aws_s3_object.code_stored_in_s3.version_id
  source_code_hash  = filebase64sha256(data.archive_file.zip_file_for_lambda.output_path)


  role          = var.iam_role
  handler       = var.handler
  runtime       = var.runtime
  timeout  = 900
  architectures = [var.arch]
  kms_key_arn = var.kms_key_arn

  memory_size = 256
  

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }

  depends_on = [
    var.iam_role
  ]
}