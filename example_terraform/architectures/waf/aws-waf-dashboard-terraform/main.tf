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


#클라우드워치 대시보드
module "waf_cloudwatch_dashboard" {
  source = "./modules/cloudwatch/dashboard"
  prefix = var.prefix
  user_tag = var.user_tag
  aws_region = var.aws_region
}
