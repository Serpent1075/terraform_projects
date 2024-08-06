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

module "analyzer_event_bridge" {
  source = "./modules/cloudwatch/analyzer"
  prefix = var.prefix
  lambda_arn = module.analyzer_lambda.lambda_arn
}


module "lambda_role" {
  source = "./modules/iam/lambda"
  prefix = var.prefix
  s3_arn = data.aws_s3_bucket.kinesis_s3.arn
}

module "analyzer_lambda" {
  source = "./modules/lambda/analyzer"
  prefix = var.prefix
  iam_role = module.lambda_role.role_arn
  runtime = "provided.al2"
  handler = "analyzer"
  bucket_name = data.aws_s3_bucket.kinesis_s3.bucket
  eventbridge_arn = module.analyzer_event_bridge.eventbridge_arn
}