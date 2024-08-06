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

//KMS 필요시 주석 제거
/*
data "aws_kms_key" "kms_seoul_arn" {
  key_id = "alias/my-key"
}
*/

######################## WAF ##################################


# Kinesis에서 WAF 로그를 전달할 s3 생성 모듈
module "kinesis_s3" { 
  source = "./modules/s3"
  prefix = var.prefix
  user_tag = var.user_tag
  account_id = data.aws_caller_identity.current.account_id
}



#Kinesis 전송 오류를 전달받을 Cloudwatch 로그 그룹 모듈
module "kinesis_cloudwatch_log_group" {
  source = "./modules/cloudwatch/log_group/kinesis"
  prefix = var.prefix
  user_tag = var.user_tag
  kinesis_name = var.kinesis_stream_name
}

#Kinesis에 할당할 IAM 역할 및 정책 모듈
module "kinesis_iam" {
  source = "./modules/iam/kinesis"
  prefix = var.prefix
  user_tag = var.user_tag
  account_id = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region
  bucketname = module.kinesis_s3.bucket_name
  stream_name = var.kinesis_stream_name
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn                                       //KMS 필요시 주석 제거
}


#Kinesis 생성 모듈
module "waf_kinesis_deliverystream" {
  source = "./modules/kinesis"
  prefix = var.prefix
  user_tag = var.user_tag
  stream_name = var.kinesis_stream_name
  iam_arn = module.kinesis_iam.iam_arn
  bucket_arn = module.kinesis_s3.bucket_arn
  cloudwatch_log_group_name = module.kinesis_cloudwatch_log_group.loggroup_name
  cloudwatch_log_stream_name = module.kinesis_cloudwatch_log_group.logstream_name
  s3_prefix = "AWSLogs/${data.aws_caller_identity.current.account_id}/"
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn                                      //KMS 필요시 주석 제거
}


#AWS WAF 생성 모듈

module "waf" {
  source = "./modules/waf"
  prefix = var.prefix
  user_tag = var.user_tag
  countrycode = ["AE"]//["RU", "CN"]
  kinesis_arn = module.waf_kinesis_deliverystream.kinesis_arn
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn                                      //KMS 필요시 주석 제거
}



####################### Snowflake Role #################

#Snowflake에서 사용할 역할 모듈
module "snowflake_iam" {
  source = "./modules/iam/snowflake"
  prefix = var.prefix
  user_tag = var.user_tag
  s3_arn = module.kinesis_s3.bucket_arn
}