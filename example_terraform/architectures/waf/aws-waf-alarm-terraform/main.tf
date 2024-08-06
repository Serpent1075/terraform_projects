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

provider "aws" {
  region = "us-east-1"
  alias = "use1"
  access_key = var.access_key
  secret_key = var.secret_key
}

data "aws_caller_identity" "current" {}


#클라우드워치 알람
module "waf_cloudwatch_alarm" {
  source = "./modules/cloudwatch/alarm"
  prefix =  var.prefix
  aws_region = var.aws_region
  sns_arn = module.slack_sns.slack-sns-arn
}


####################### Alarm CloudWatch SNS to Slack Lambda  ###############

module "slack_lambda_role" {
  source = "./modules/iam/lambda"
  prefix = var.prefix
}

module "slack_lambda" {
  source = "./modules/lambda"
  prefix = var.prefix
  iam_role = module.slack_lambda_role.lambda-iam-instance-arn
  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"
  client_name = var.client_name
}

module "slack_sns" {
  source = "./modules/sns/wafeventalarm"
  prefix = var.prefix
  account_id = data.aws_caller_identity.current.account_id
  lambda_arn = module.slack_lambda.lambda-arn
  lambda_name = module.slack_lambda.lambda-name
}

module "waf_rule_update" {
  source = "./modules/sns/wafruleupdate"
  providers = {
    aws = aws.use1
  }
  lambda_arn = module.slack_lambda.lambda-arn
}

