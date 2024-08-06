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

data "aws_kms_key" "kms_seoul_arn" {
  key_id = "alias/resource_state"
}

module "event_bridge" {
  source = "./modules/cloudwatch/eventbridge"
  prefix = var.prefix
  lambda_arn = module.resource_state_lambda.lambda_arn
}

module "lambda_role" {
  source = "./modules/iam/lambda"
  prefix = var.prefix
  kms_arns = [data.aws_kms_key.kms_seoul_arn.arn]
}

module "resource_state_lambda" {
  source = "./modules/lambda"
  prefix = var.prefix
  iam_role = module.lambda_role.role_arn
  runtime = "provided.al2"
  handler = "resource_state"
  eventbridge_arn = module.event_bridge.eventbridge_arn
}