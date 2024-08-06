terraform {
    required_providers {
      aws = {
          source ="hashicorp/aws"
          version = "~> 4.4"
      }

    }

    required_version = ">= 1.2.0"
}


provider "aws" {
    region = var.aws_region
    access_key = var.access_key
    secret_key = var.secret_key
}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "kinesis_s3" {
  bucket = "aws-waf-logs-${var.prefix}"
}

module "partitioning_event_bridge" {
  source = "./modules/cloudwatch/partitioning"
  prefix = var.prefix
  lambda_arn = module.partitioning_lambda.lambda_arn
}


module "lambda_role" {
  source = "./modules/iam/lambda"
  prefix = var.prefix
  s3_arn = data.aws_s3_bucket.kinesis_s3.arn
}

module "partitioning_lambda" {
  source = "./modules/lambda/partitioning"
  prefix = var.prefix
  iam_role = module.lambda_role.role_arn
  runtime = "provided.al2"
  handler = "partitioning"
  database_name = module.waf_athena.athena_database
  workgroup_name = module.waf_athena.workgroup_name
  bucket_name = data.aws_s3_bucket.kinesis_s3.bucket
  eventbridge_arn = module.partitioning_event_bridge.eventbridge_arn
}


module "waf_athena" {
  source = "./modules/athena"
  prefix = var.prefix
  aws_region = var.aws_region
  s3_bucket_id = data.aws_s3_bucket.kinesis_s3.id
  s3_bucket_name = data.aws_s3_bucket.kinesis_s3.bucket
  account_id = data.aws_caller_identity.current.account_id
}