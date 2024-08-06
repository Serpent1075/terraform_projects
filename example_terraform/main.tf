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
  alias = "us-east-1"
  region = "us-east-1"
}
data "aws_caller_identity" "current" {}

/*

data "aws_ami" "webapiami" {
  executable_users = ["self"]
  most_recent      = true
  owners           = ["self"]
}
*/

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "()!#"
}
 
/*
data "aws_acm_certificate" "amazon_issued" {
  domain      = var.domain_address
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
*/
module "vpc" {
    source = "./modules/vpc"
    prefix = var.prefix
    cidr_vpc = var.cidr_vpc
    az_a = var.az_a
    az_c = var.az_c
    cidr_pub_a = var.cidr_pub_a
    cidr_pub_b = var.cidr_pub_b
    cidr_pri_a = var.cidr_pri_a
    cidr_pri_b = var.cidr_pri_b
    cidr_batch_a = var.cidr_batch_a
    cidr_batch_b = var.cidr_batch_b

    //pub_nat_eip_private = var.pub_nat_eip_private
}


/*
module "kms" {
  source ="./modules/kms"
  multi_region = true
  aws_region = var.aws_region
  prefix   = var.prefix
  account_id = data.aws_caller_identity.current.account_id
  user = var.username
}

data "aws_kms_key" "kms_seoul_arn" {
  key_id = "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/mrk-3bdea55f8a8748ec90e45504ee8c6211"
}

data "aws_kms_key" "kms_us_arn" {
  provider = aws.us-east-1
  key_id = "arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:key/mrk-3bdea55f8a8748ec90e45504ee8c6211"
}

module "log-bucket" {
  source = "./modules/s3/log"
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}
*/
/*
module "kms-policy" {
  source = "./modules/iam/kms"
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}
*/
/*
module "ecs-iam" {
  source = "./modules/iam/webapi_ecs"
  prefix = var.prefix
  aws_region = var.aws_region
  role_policy_arns = [module.kms-policy.iam-policy-arn]
}

*/
module "ec2_iam" {
  source = "./modules/iam/webapi_ec2"
  prefix = var.prefix
  aws_region = var.aws_region
  //role_policy_arns = [module.kms-policy.iam-policy-arn]
}


/*

module "batch-ecs-iam" {
  source = "./modules/iam/batch"
  prefix = var.prefix
  account_id = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}


module "rds-iam" {
  source = "./modules/iam/rds"
  kms_arns = [data.aws_kms_key.kms_seoul_arn.arn]
}
*/

/*
module "code-bucket" {
  source = "./modules/s3/code"
  prefix = var.prefix
  kms-arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "lambdaedge-bucket" {
  source = "./modules/s3/lambdaedge"
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_us_arn.arn
}*/

module "batch-sg" {
  source = "./modules/security_group/batch"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
}

module "efs-sg"{
  source = "./modules/security_group/efs"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  webapi-sg = module.webapi-sg.security-group-id
  batch-sg = module.batch-sg.security-group-id
  nfsport = 2049
}


module "ps_cw_standalone" {
  source = "./modules/parameterstore"
  ps_cw_config_name = var.ps_cw_config_standalone_name
  filename = "ps_cw_standalone_config"
}

/*
module "webapi-standalone-sg" {
    source = "./modules/security_group/standalone"
    prefix = var.prefix
    vpc_id = module.vpc.vpc_id
    webapi_port = 443
    ssh_port = var.ssh_port
    source_cidr_blocks_for_all_outbound_ipv4 = var.all_ipv4
    source_cidr_blocks_for_all_outbound_ipv6 = var.all_ipv6
    source_cidr_blocks_for_ssh_ipv4 = var.all_ipv4
    source_cidr_blocks_for_ssh_ipv6 = var.all_ipv6
    source_cidr_blocks_for_web_ipv4 = var.all_ipv4
    source_cidr_blocks_for_web_ipv6 = var.all_ipv6
}

module "webapi-standalone-launchtemplate" {
    source = "./modules/launch_template/standalone"
    prefix = var.prefix
    aws_region = var.aws_region
    image_id = var.webapi-standalone-ami-id
    iam-name = module.ec2_iam.iam-instance-profile-name
    sg-id = module.webapi-standalone-sg.security-group-id
    instance_type = var.webapi-standalone-instance-type
    key_name = var.webapi-key-name
    webapi-subnet-id = module.vpc.public_subnet_a_id
    ps-cw-config = var.ps_cw_config_standalone_name
}

module "efs" {
  source = "./modules/efs"
  prefix = var.prefix
  pri_sub_a_id = module.vpc.private_subnet_a_id
  pri_sub_b_id = module.vpc.private_subnet_b_id
  kms_key_arn = data.aws_kms_key.kms_seoul_arn.arn
  efs-sg = [module.efs-sg.security-group-id]
}

module "ps_cw" {
  source = "./modules/parameterstore"
  ps_cw_config_name = var.ps_cw_config_name
  filename = "ps_cw_config"
}


data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}
*/
module "webapi-sg" {
    source = "./modules/security_group/webapi"
    prefix = var.prefix
    vpc_id = module.vpc.vpc_id
    webapi_port = var.webapi_port
    ssh_port = var.ssh_port
    source_cidr_blocks_for_all_outbound_ipv4 = var.all_ipv4
    source_cidr_blocks_for_all_outbound_ipv6 = var.all_ipv6
    source_cidr_blocks_for_ssh_ipv4 = var.all_ipv4
    source_cidr_blocks_for_ssh_ipv6 = var.all_ipv6
    source_cidr_blocks_for_web_ipv4 = var.all_ipv4
    source_cidr_blocks_for_web_ipv6 = var.all_ipv6
}
module "alb-sg"{
  source = "./modules/security_group/loadbalancer"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  http = 80
  https = 443
}


/*
module "webapi-launchtemplate" {
    source = "./modules/launch_template/webapi"
    prefix = var.prefix
    aws_region = var.aws_region
    image_id = var.webapi-ami-id
    iam-name = module.ec2_iam.iam-instance-profile-name
    sg-id = module.webapi-sg.security-group-id
    instance_type = var.webapi-instance-type
    key_name = var.webapi-key-name
    webapi-subnet-id = module.vpc.private_subnet_a_id
    file-system-id = module.efs.file-system-id
    ps-cw-config = var.ps_cw_config_name
}


module "webapi_alb" {
  source = "./modules/loadbalancer/webapi"
  prefix = var.prefix
  domain_address = var.domain_address
  vpc_id = module.vpc.vpc_id
  subnets_ids = [module.vpc.public_subnet_a_id, module.vpc.public_subnet_b_id]
  sg = [module.alb-sg.security-group-id]
  app_port = var.webapi_port
  acm_arn = data.aws_acm_certificate.amazon_issued.arn
}
*/
/*
module "webapi_asg" {
   source = "./modules/autoscaling/webapi"
   prefix = var.prefix
   aws_region = var.aws_region
   launch_template_id = module.webapi-launchtemplate.launch-template-id
   zone_id = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
   alb_targetgroup_arn = module.webapi_alb.alb-target-group-arn
}




module "ecs_alb_sg"{
  source = "./modules/security_group/loadbalancer"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  http = 80
  https = 443
}

module "ecs_webapi_alb" {
  source = "./modules/loadbalancer/webecs"
  prefix = "${var.prefix}"
  domain_address = var.domain_address
  vpc_id = module.vpc.vpc_id
  subnets_ids = [module.vpc.public_subnet_a_id, module.vpc.public_subnet_b_id]
  sg = [module.ecs_alb_sg.security-group-id]
  app_port = var.webapi_port
  acm_arn = data.aws_acm_certificate.amazon_issued.arn
}

module "webapi_ecr" {
  source = "./modules/ecr/webapi"
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "ecs-cloudwatch-log-group" {
  source = "./modules/cloudwatch/ecs"
  prefix = var.prefix
  name = "ecs-cloudwatch-log-group"
  cloudwatch_log_groups_kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "webapi-ecs" {
  source = "./modules/ecs"
  prefix = var.prefix
  aws_region = var.aws_region
  imagename = "webapi"
  lb_tg_arn = module.ecs_webapi_alb.alb-target-group-arn
  subnets_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
  sg = [module.webapi-sg.security-group-id]
  iam_arn = module.ecs-iam.iam-instance-arn
  task_execution_arn = data.aws_iam_role.ecs_task_execution_role.arn
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  loggroup_name = module.ecs-cloudwatch-log-group.loggroup-name
  image_url = module.webapi_ecr.container-registry-url
  file_system_id = module.efs.file-system-id
  file_system_access_point = module.efs.efs_access_point
}
*/

#############################LoadBalancer#################################
/*

data "aws_subnets" "public" {
  
  filter {
    name = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name = "tag:Type"
    values = ["Public"]
  }
}

data "aws_acm_certificate" "examplecom" {
  domain      = "${var.domain_address}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}


module "ext_alb" {
  source = "./modules/loadbalancer/alb"
  prefix = "Prd-Ext-Alb"
  sufix = "${var.prefix}"
  vpc_id = module.vpc.vpc_id
  subnets_ids = [data.aws_subnets.public.ids[0],data.aws_subnets.public.ids[1]]
  sg = [module.alb-sg.security-group-id]
  app_port = 8080
  acm_arn = data.aws_acm_certificate.examplecom.arn
}

module "ext_nlb" {
  source = "./modules/loadbalancer/nlb/tls"
  prefix = "Prd-Ext-Nlb"
  sufix = "${var.prefix}"
  vpc_id = data.aws_vpc.cloudtft_testvpc.id
  subnets_ids = [data.aws_subnets.public.ids[0],data.aws_subnets.public.ids[1]]
  sg = [module.alb-sg.security-group-id]
  listener_port = 443
  https_app_port = 8080
  http_app_port = 80
  acm_arn = data.aws_acm_certificate.wjthinkbigcom.arn
}

module "int_nlb" {
  source = "./modules/loadbalancer/nlb/tcp"
  prefix = "Prd-Int-Nlb"
  sufix = "${var.prefix}"
  vpc_id = data.aws_vpc.cloudtft_testvpc.id
  subnets_ids = [data.aws_subnets.private.ids[0],data.aws_subnets.private.ids[1]]
  sg = [module.alb-sg.security-group-id]
  listener_https_port = 8080
  listener_http_port = 80
  https_app_port = 8080
  http_app_port = 80
}
*/
############################### CI/CD ###################################
/*
module "code-repository" {
  source = "./modules/code/codecommit"
  prefix = var.prefix
}


module "codebuild-iam" {
  source = "./modules/iam/code/codebuild"
  account_num = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region
  repository_arn = module.code-repository.code-repository-arn
  bucket_name = module.code-bucket.bucket-name
  codebuild_name = "${var.prefix}-project"
}
module "code-buildmachine" {
  source = "./modules/code/codebuild"
  prefix = var.prefix
  iam_arn = module.codebuild-iam.iam-instance-arn
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  source_type = "CODECOMMIT"
  source_location = module.code-repository.code-repository-clone-url-http
  codebuildbucket-name = module.code-bucket.bucket-name
  buildspec = var.buildspec
  git_token = var.github_token
  bucket_name = module.code-bucket.bucket-name
  s3_path = var.codebuild_artifacts_s3_path
  artifact_name = var.artifact_name
  architecture = var.x86_arch
}
module "codedeploy-iam" {
  source = "./modules/iam/code/codedeploy"
}



module "code-deploymachine" {
  source = "./modules/code/codedeploy"
  prefix = var.prefix
  iam_arn = module.codedeploy-iam.iam-instance-arn
  asg_name = [module.webapi_asg.asg-name]
  tg_name =module.webapi_alb.alb-target-group-name
}

module "codepipeline-iam"{
  source = "./modules/iam/code/codepipeline"
  aws_region = var.aws_region
  account_num = data.aws_caller_identity.current.account_id
  codecommit_arn = module.code-repository.code-repository-arn
  code_bucket_arn = module.code-bucket.bucket-arn
  
}

module "code-pipeline" {
  source = "./modules/code/codepipeline"
  prefix = var.prefix
  aws_region = var.aws_region
  iam_arn = module.codepipeline-iam.iam-instance-arn
  code_bucket = module.code-bucket.bucket-name
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  codecommit_id = module.code-repository.code-repository-id
  codebuild_name = module.code-buildmachine.project-name
  codedeploy_app_name = module.code-deploymachine.application-name
  codedeploy_deploy_group_name = module.code-deploymachine.deployment-group-name
}
*/
####################### Reids ####################
/*
module "redis-sg" {
  source = "./modules/security_group/redis"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  redisport= var.redisport
  webapi_sg_id = module.webapi-sg.security-group-id
  batch_sg_id = module.batch-sg.security-group-id
  lambda_sg_id = module.lambda-sg.security-group-id
}
module "redis-cloudwatch-log-group" {
  source = "./modules/cloudwatch/redis"
  prefix = var.prefix
  name = "redis-cloudwatch-log-group"
  cloudwatch_log_groups_kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "redis" {
  source = "./modules/redis"
  prefix = var.prefix
  node_type = "cache.t3.small"
  family = "redis6.x"
  redisport = var.redisport
  sg_group_ids = [module.redis-sg.security-group-id]
  loggroup-name = module.redis-cloudwatch-log-group.loggroup-name
  subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
  maintenance_date = var.maintenance_date
}
*/
####################### RDS ###################

module "rds-sg" {
  source = "./modules/security_group/rds"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  psqlport = var.psqlport
  webapi_sg_id = module.webapi-sg.security-group-id
  batch_sg_id = module.batch-sg.security-group-id
  lambda_sg_id = module.lambda-sg.security-group-id
}

resource "aws_db_subnet_group" "rds_sb_group" {
  name       = "${var.prefix}-rds-subnet-group"
  subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]

  tags = {
    Name = "My DB subnet group"
  }
}

/*
module "rds" {
  source = "./modules/rds/db"
  prefix = var.prefix
  subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
  engine = "aurora-postgresql"
  psqlversion = "14.3"#"13.6"
  family = "aurora-postgresql14"#"aurora-postgresql13"
  database_name = var.database_name
  writer_instance_class = "db.t3.medium" #db.t3.medium  db.r6g.large
  reader_instance_class = "db.t3.medium" #Global은 t3지원 안함
  adminname = var.username
  password = "${random_password.password.result}"
  psqlport = var.psqlport
  iam_roles = [module.rds-iam.iam-instance-arn]
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  vpc_security_group_ids = [module.rds-sg.security-group-id]
  maintenance_date = var.maintenance_date
}
*/

/*
module "rds-sg-prod" {
  source = "./modules/security_group/rds"
  prefix = "${var.prefix}-prod"
  vpc_id = module.vpc-prod.vpc_id
  psqlport = var.psqlport
  webapi_sg_id = module.webapi-sg-prod.security-group-id
  //batch_sg_id = module.batch-sg.security-group-id
  //lambda_sg_id = module.lambda-sg.security-group-id
}

module "rds-prod" {
  source = "./modules/rds/cluster/multi_instance"
  prefix = "${var.prefix}-prod"
  subnet_ids = [module.vpc-prod.db_subnet_a_id, module.vpc-prod.db_subnet_b_id]
  engine = "aurora-postgresql"
  psqlversion = "14.3"#"13.6"
  family = "aurora-postgresql14"#"aurora-postgresql13"
  database_name = var.database_name
  writer_instance_class = "db.t3.medium" #db.t3.medium  db.r6g.large
  reader_instance_class = "db.t3.medium" #Global은 t3지원 안함
  adminname = var.psqlusername
  password = "J9k247VbzV2cBzKeCyca"
  psqlport = var.psqlport
  iam_roles = [module.rds-iam.iam-instance-arn]
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  vpc_security_group_ids = [module.rds-sg-prod.security-group-id]
  maintenance_date = var.maintenance_date
}

module "rds-sg-stage" {
  source = "./modules/security_group/rds"
  prefix = "${var.prefix}-stage"
  vpc_id = module.vpc-stage.vpc_id
  psqlport = var.psqlport
  webapi_sg_id = module.webapi-sg-stage.security-group-id
  //batch_sg_id = module.batch-sg.security-group-id
  //lambda_sg_id = module.lambda-sg.security-group-id
}

module "rds-stage" {
  source = "./modules/rds/cluster/single_instance"
  prefix = "${var.prefix}-stage"
  subnet_ids = [module.vpc-stage.db_subnet_a_id, module.vpc-stage.db_subnet_b_id]
  engine = "aurora-postgresql"
  psqlversion = "14.3"#"13.6"
  family = "aurora-postgresql14"#"aurora-postgresql13"
  database_name = var.database_name
  writer_instance_class = "db.t3.medium" #db.t3.medium  db.r6g.large
  adminname = var.psqlusername
  password = "J9k247VbzV2cBzKeCyca"
  psqlport = var.psqlport
  iam_roles = [module.rds-iam.iam-instance-arn]
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  vpc_security_group_ids = [module.rds-sg-stage.security-group-id]
  maintenance_date = var.maintenance_date
}
*/
####################### lambda ###############
/*
module "cloudwatch-batchlambda" {
  source = "./modules/cloudwatch/lambda"
  lambda_function_name = "batchlambda"
}

module "lambda-iam"{
  source = "./modules/iam/lambda/batchlambda"
  prefix = var.prefix
  kms_arns = [data.aws_kms_key.kms_seoul_arn.arn]
}
*/
module "lambda-sg" {
  source = "./modules/security_group/lambda"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
}
/*
module "batchlambda" {
   source = "./modules/lambda/batchlambda"
   prefix = var.prefix
   name = "batchlambda"
   iam_role = module.lambda-iam.lambda-iam-instance-arn
   handler = "batchlambda"
   runtime = "go1.x"
   arch = "x86_64"
   kms_key_arn = data.aws_kms_key.kms_seoul_arn.arn
   vpc_subnet_ids = [module.vpc.batch_subnet_a_id, module.vpc.batch_subnet_b_id]
   vpc_security_group_ids = [module.lambda-sg.security-group-id]
   path_source_dir = "D:\\tech\\terraformproject\\example\\modules\\lambda\\batchlambda\\lambdaapp\\"
   cw_log_group = module.cloudwatch-batchlambda.loggroup-id
}

*/
####################### Batch ###################################



module "endpoint-sg" {
  source = "./modules/security_group/endpoint"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
}
/*
module "batch-endpoint" {
  source = "./modules/endpoint/batch"
  prefix = "${var.prefix}-batch"
  aws_region = var.aws_region
  vpc_id = module.vpc.vpc_id
  subnet_ids = [module.vpc.batch_subnet_a_id] #[module.vpc.batch_subnet_a_id]
  #subnet 개수에 따라 요금이 배로 증가
  #subnet_ids = [module.vpc.batch_subnet_a_id, module.vpc.batch_subnet_b_id]
  endpoint_sg_id = module.endpoint-sg.security-group-id
  route_table_id = module.vpc.batch_rt_id #module.vpc.batch_rt_id
  batch_iam_arn = module.batch-ecs-iam.batch-iam-service-arn
  ecs_iam_arn = data.aws_iam_role.ecs_task_execution_role.arn
}

module "ecs-endpoint" {
  source = "./modules/endpoint/ecs"
  prefix = "${var.prefix}-ecs"
  aws_region = var.aws_region
  vpc_id = module.vpc.vpc_id
  subnet_ids = [module.vpc.private_subnet_a_id] #[module.vpc.batch_subnet_a_id]
  #subnet 개수에 따라 요금이 배로 증가
  #subnet_ids = [module.vpc.batch_subnet_a_id, module.vpc.batch_subnet_b_id]
  endpoint_sg_id = module.endpoint-sg.security-group-id
  route_table_id = module.vpc.private_rt_id #module.vpc.batch_rt_id
  ecs_iam_arn = data.aws_iam_role.ecs_task_execution_role.arn
}

*/
/*
module "prefix-secretmanager" {
  source = "./modules/secretmanager"
  aws_region = var.aws_region
  prefix = "my"
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  secretname = "prefix"

  secret_value = {
    prefix = "${var.prefix}"
    cfurl = "https://cdn.${var.domain_address}/prod/"
    buildbehavior = "${var.build_behavior}"
  }
}


module "redis-secretmanager" {
  source = "./modules/secretmanager"
  aws_region = var.aws_region
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  secretname = "${var.build_behavior}/redis"
  secret_value = {
    redisendpoint = "${module.redis.configuration-endpoint-address}"
    redisport = "${var.redisport}"
  }
}


module "rds-secretmanager" {
  source = "./modules/secretmanager"
  aws_region = var.aws_region
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  secretname = "${var.build_behavior}/rds"
  secret_value = {
    psqlreaderendpoint = "${module.rds.reader-endpoint}"
    psqlwriterendpoint = "${module.rds.endpoint}"
    username = "${var.psqlusername}"
    psqlport = "${var.psqlport}"
    dbname = "${var.database_name}"
  }
}

module "mongo-secretmanager" {
  source = "./modules/secretmanager"
  aws_region = var.aws_region
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  secretname = "${var.build_behavior}/mongo"
  secret_value = {
    mongourl = "${var.mongourl}"
  }
}

module "pw-secretmanager" {
  source = "./modules/secretmanager"
  aws_region = var.aws_region
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  secretname = "${var.build_behavior}/secret"
  secret_value = {
    password = "${random_password.password.result}"
  }
}



module "batch_ecr" {
  source = "./modules/ecr/batch"
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "batch" {
  source = "./modules/batch"
  account_id = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region
  prefix = var.prefix
  subnet_ids = [module.vpc.batch_subnet_a_id, module.vpc.batch_subnet_b_id]
  batch-iam-arn = module.batch-ecs-iam.batch-iam-service-arn
  compute_security_group_id = module.batch-sg.security-group-id
  app_name = "myapp"
  image_name = "batch-image"
  instance_type = "c6g.small"
  vcpu = 1
  mem = 2048
  efsname = "urmyefs"
  efs_file_system_id = module.efs.file-system-id
  sm_prefix_arn = module.prefix-secretmanager.secret_arn
  sm_redis_arn = module.redis-secretmanager.secret_arn
  sm_rds_arn = module.rds-secretmanager.secret_arn
  sm_pw_arn = module.pw-secretmanager.secret_arn
  sm_mongo_arn = module.mongo-secretmanager.secret_arn
}
*/
############################### CDN ###################################
/*
data "aws_canonical_user_id" "current" {}


module "lambdaedge-cloudwatch-loggroup"{
  source = "./modules/cloudwatch/lambdaedge"
  prefix = var.prefix
  name = "viewerrequest"
  cloudwatch_log_groups_kms_arn = data.aws_kms_key.kms_us_arn.arn
}



module "cloudfront-bucket" {
  source = "./modules/s3/cloudfront"
  prefix = var.prefix
  account_id = data.aws_canonical_user_id.current.id
}
*/
/*
module "lambdaedge-iam" {
  source = "./modules/iam/lambda/lambdaedge"
  kms_arns = [data.aws_kms_key.kms_seoul_arn.arn, data.aws_kms_key.kms_us_arn.arn]
  //loggroup_arn = module.lambdaedge-cloudwatch-loggroup.loggroup-arn
}
module "lambdaedge-viewerrequest" {
  source = "./modules/lambda/lambdaedge"
  prefix = var.prefix
  name = "viewerrequest"
  mem_size = 128
  ephemeral_storage_size = 512
  s3_artifact_bucket = module.lambdaedge-bucket.bucket-name
  iam_arn = module.lambdaedge-iam.iam-instance-arn
  kms_replica_arn = data.aws_kms_key.kms_us_arn.arn
  path_source_dir = "D:\\tech\\terraformproject\\example\\modules\\lambda\\lambdaedge\\"
}

module "lambdaedge-originresponse" {
  source = "./modules/lambda/lambdaedge"
  prefix = var.prefix
  name = "originresponse"
  mem_size = 1024
  ephemeral_storage_size = 512
  s3_artifact_bucket = module.lambdaedge-bucket.bucket-name
  iam_arn = module.lambdaedge-iam.iam-instance-arn
  kms_replica_arn = data.aws_kms_key.kms_us_arn.arn
  path_source_dir = "D:\\tech\\terraformproject\\example\\modules\\lambda\\lambdaedge\\"
}

module "cloudfront" {
  source = "./modules/cloudfront"
  prefix = var.prefix
  bucket_regional_domain_name = module.cloudfront-bucket.bucket-domain-name
  log_bucket_name = module.log-bucket.bucket-domain-name
  log_bucket_prefix = "cloudfront"
  list_alias_domain = ["contents.${var.domain_address}"]
  origin_bucket_name = module.cloudfront-bucket.bucket-name
  origin_bucket_id = module.cloudfront-bucket.bucket-id
  origin_bucket_arn = module.cloudfront-bucket.bucket-arn
  domain_address = var.domain_address
  ec2_iam_arn = module.ec2_iam.iam-instance-arn
  propic_origin_path = "users"
  terms_origin_path = "org"
  lambda_iam_arn = module.lambdaedge-iam.iam-instance-arn
  #테라폼으로 람다엣지 삭제시 Cloudfront에 연결되어 있었을 경우, 
  #연결 해제에 오래 걸려, 시간이 지나고 수동으로 삭제해주어야함
  #https://github.com/hashicorp/terraform-provider-aws/issues/1721
  viewer_req_lambda_arn = module.lambdaedge-viewerrequest.arn
  origin_resp_lambda_arn = module.lambdaedge-originresponse.arn
}
*/

####################### Network Firewall ########################
/* 한달 약 400달러나옴
module "network-firewall" {
  source = "./modules/networkfirewall"
  prefix = var.client_name
  vpc_id = module.vpc.vpc_id
  account_id = data.aws_caller_identity.current.account_id
  subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
}
*/
######################## WAF ##################################
/*
data "aws_lb" "conn" {
  name = "jhoh-alb"
  
}

data "aws_security_group" "selected" {
  id = "sg-0036d9255bcc9ac11"
}


module "webapi_alb" {
  source = "./modules/loadbalancer/webapi"
  prefix = var.prefix
  user_tag = var.user_tag
  vpc_id = data.aws_vpc.cloudtft_testvpc.id
  subnets_ids = [data.aws_subnets.subnets.ids[0],data.aws_subnets.subnets.ids[1]]
  sg = [data.aws_security_group.selected.id]
  app_port = 3010
  domain_address = var.domain_address
  acm_arn = data.aws_acm_certificate.amazon_issued.arn
}


data "aws_s3_bucket" "selected" {
  bucket = "jhoh-tf-private-test"
}
*/
/*
module "kinesis_cloudwatch_log_group" {
  source = "./modules/cloudwatch/log_group/kinesis"
  prefix = var.prefix
  user_tag = var.user_tag
  kinesis_name = "deliverystream"
}

module "kinesis_iam" {
  source = "./modules/iam/kinesis"
  prefix = var.prefix
  user_tag = var.user_tag
  account_id = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region
  bucketname = data.aws_s3_bucket.selected.bucket
  stream_name = "aws-waf-logs-deliverystream"
  //cluster_arn = module.waf_opensearch.opensarch_arn
  //opensearch_domain_arn = module.waf_opensearch.opensarch_arn
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "waf_kinesis_deliverystream" {
  source = "./modules/kinesis"
  prefix = var.prefix
  user_tag = var.user_tag
  stream_name = "aws-waf-logs-deliverystream"
  iam_arn = module.kinesis_iam.iam_arn
  bucket_arn = data.aws_s3_bucket.selected.arn
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  cloudwatch_log_group_name = module.kinesis_cloudwatch_log_group.loggroup_name
  cloudwatch_log_stream_name = module.kinesis_cloudwatch_log_group.logstream_name
  s3_prefix = "nolbal/"
 //cluster_arn = module.waf_opensearch.opensarch_arn
  subnet_ids = data.aws_subnets.subnets.ids
  //opensearch_sg = [module.opensearch_sg.security_group_id]
}


module "waf_cloudwatch" {
  source = "./modules/cloudwatch/log_group/waf"
  prefix = var.prefix
  user_tag = var.user_tag

}

module "waf" {
  source = "./modules/waf"
  prefix = var.prefix
  user_tag = var.user_tag
  countrycode = ["RU", "CN"]
  kinesis_arn = module.waf_kinesis_deliverystream.kinesis_arn
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn                                      //KMS 필요시 주석 제거
}

*/
#####################OpenSearch###########################
/*
module "opensearch_sg" {
  source = "./modules/security_group/opensearch"
  prefix = var.prefix
  user_tag = var.user_tag
  vpc_id = data.aws_vpc.cloudtft_testvpc.id
}


module "waf_opensearch" {
  source = "./modules/opensearch"
  prefix = var.prefix
  user_tag = var.user_tag
  account_id = data.aws_caller_identity.current.account_id
  region =  var.aws_region
  domain = var.opensearch_domain
  subnet_ids = data.aws_subnets.subnets.ids
  opensearch_sg = [module.opensearch_sg.security_group_id]
  acm_arn = data.aws_acm_certificate.amazon_issued.arn
  domain_address = "opensearch.${var.domain_address}"
  //log_group_arn = module.opensearch_cloudwatch_log_group.loggroup_arn
  //user_pool_id = module.opensearch_cognito.user_pool_id
  //identity_pool_id = module.opensearch_cognito.identity_pool_id
  //cognito_iam_arn = module.opensearch_iam.iam_arn
}

module "waf_elasticsearch" {
  source = "./modules/elasticsearch"
  prefix = var.prefix
  user_tag = var.user_tag
  account_id = data.aws_caller_identity.current.account_id
  region =  var.aws_region
  domain_name = var.elasticsearch_domain
  subnet_ids = data.aws_subnets.subnets.ids
  elastic_search_sg_ids = [module.opensearch_sg.security_group_id]
  
  
  //log_group_arn = module.opensearch_cloudwatch_log_group.loggroup_arn
  //user_pool_id = module.opensearch_cognito.user_pool_id
  //identity_pool_id = module.opensearch_cognito.identity_pool_id
  //cognito_iam_arn = module.opensearch_iam.iam_arn
}

module "opensearch_iam"{
  source = "./modules/iam/opensearch"
  prefix = var.prefix
  user_tag = var.user_tag
  aws_region = var.aws_region  
}

*/


/*
module "opensearch_cognito" {
  source = "./modules/cognito"
  prefix = var.prefix
  user_tag = var.user_tag
  opensearch_domain = module.waf_opensearch.opensarch_domain
  acm_arn = data.aws_acm_certificate.amazon_issued.arn
}
*/

#######################Kubernetes#######################

/*
module "kuber_fargate_vpc" {
  source = "./modules/vpc/eksnetwork"
  prefix = "${var.prefix}-fargate"
  cluster_name = var.fargate_cluster_name
  vpc_id = module.vpc.vpc_id
  igw_id = module.vpc.igw_id
  cidr_kuber_pub_a = var.cidr_fargate_kuber_pub_a
  cidr_kuber_pub_b = var.cidr_fargate_kuber_pub_b
  cidr_kuber_pub_c = var.cidr_fargate_kuber_pub_c
  cidr_kuber_pri_a = var.cidr_fargate_kuber_pri_a
  cidr_kuber_pri_b = var.cidr_fargate_kuber_pri_b
  cidr_kuber_pri_c = var.cidr_fargate_kuber_pri_c
  az_a = var.az_a
  az_b = var.az_b
  az_c = var.az_c
  pub_kuber_nat_eip_private = var.pub_fargate_kuber_nat_eip_private
}

*/

module "kuber_ec2_vpc" {
  source = "./modules/vpc/eksnetwork"
  prefix = "${var.prefix}-ec2"
  cluster_name = var.ec2_cluster_name
  vpc_id = module.vpc.vpc_id
  igw_id = module.vpc.igw_id
  cidr_kuber_pub_a = var.cidr_ec2_kuber_pub_a
  cidr_kuber_pub_b = var.cidr_ec2_kuber_pub_b
  cidr_kuber_pub_c = var.cidr_ec2_kuber_pub_c
  cidr_kuber_pri_a = var.cidr_ec2_kuber_pri_a
  cidr_kuber_pri_b = var.cidr_ec2_kuber_pri_b
  cidr_kuber_pri_c = var.cidr_ec2_kuber_pri_c
  az_a = var.az_a
  az_b = var.az_b
  az_c = var.az_c
  pub_kuber_nat_eip_private = var.pub_ec2_kuber_nat_eip_private
}

module "harbor-bucket" {
  source = "./modules/s3/harbor"
  prefix = var.prefix
}




module "kuber-cluster-sg" {
  source = "./modules/security_group/eks/cluster"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  //cluster_name = var.ec2_cluster_name
}
module "kuber-node-sg" {
  source = "./modules/security_group/eks/node"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  cluster_sg_id = module.kuber-cluster-sg.security-group-id
  alb_sg_id = module.alb-sg.security-group-id
  //cluster_name = var.ec2_cluster_name
  //launch_template_id = module.eks_launchtemplate.launch-template-id
  //launch_template_version = module.eks_launchtemplate.launch-template-version
  //node_group_name = module.kuber-ec2.node_group_name
}

module "kuber-cluster-role" {
  source = "./modules/iam/eks"
  prefix = var.prefix
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "kuber-worker-node-role" {
  source = "./modules/iam/eks/ec2"
  prefix = var.prefix
}


/*
module "kuber-endpoint" {
  source = "./modules/endpoint/kuber"
  prefix = "${var.prefix}_ec2_kuber"
  aws_region = var.aws_region
  vpc_id = module.vpc.vpc_id
  subnet_ids = [module.kuber_ec2_vpc.kuber_private_subnet_a_id] #[module.vpc.batch_subnet_a_id]
  //module.kuber_ec2_vpc.kuber_private_subnet_b_id, module.kuber_ec2_vpc.kuber_private_subnet_c_id
  #subnet 개수에 따라 요금이 배로 증가
  #subnet_ids = [module.vpc.batch_subnet_a_id, module.vpc.batch_subnet_b_id]
  endpoint_sg_id = module.endpoint-sg.security-group-id
  list_iam_arn = [module.kuber-cluster-role.kuber-cluster-role-arn, module.kuber-worker-node-role.kuber-ec2-role-arn,module.kuber-ec2.iam_sa_role] #module.kubernetes-fargate.cluster_iam_role_arn
}

module "kuber-ec2" {
  source = "./modules/eks/ec2"
  prefix = var.prefix 
  cluster_name = "${var.ec2_cluster_name}"
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  subnet_ids = [module.kuber_ec2_vpc.kuber_public_subnet_a_id, module.kuber_ec2_vpc.kuber_public_subnet_b_id, module.kuber_ec2_vpc.kuber_public_subnet_c_id]
  //subnet_ids = [module.kuber_ec2_vpc.kuber_private_subnet_a_id, module.kuber_ec2_vpc.kuber_private_subnet_b_id, module.kuber_ec2_vpc.kuber_private_subnet_c_id]
  cluster_sg = module.kuber-cluster-sg.security-group-id
  ec2_ssh_key = var.webapi-key-name
  cluster_role_arn = module.kuber-cluster-role.kuber-cluster-role-arn
  ec2_role_arn = module.kuber-worker-node-role.kuber-ec2-role-arn
  alb_controller_policy_arn = module.kuber-cluster-role.kuber_load_balancer_controller_policy_arn
  lt_id = module.eks_launchtemplate.launch-template-id
}
module "eks_launchtemplate" {
    source = "./modules/launch_template/eks_worker_node"
    prefix = var.prefix
    aws_region = var.aws_region
    image_id = "ami-0f353bd1d81aef365"
    iam-name = module.kuber-worker-node-role.kuber-ec2-role-profile-name
    sg-ids = [module.kuber-node-sg.security-group-id]
    instance_type = "t3.medium"
    key_name = var.webapi-key-name
    node_subnet_id = module.vpc.private_subnet_a_id
    cluster_name = "${var.ec2_cluster_name}"
}
*/

/*


#fargate externalmodule 
module "kubernetes-fargate" {
  source = "./modules/eks/externalmodule/fargate"
  prefix = var.prefix
  account_id = data.aws_caller_identity.current.account_id
  cluster_name = var.fargate_cluster_name
  aws_region = var.aws_region
  vpc_id = module.vpc.vpc_id
  username = ["jhoh"]
  subnet_ids = [module.kuber_fargate_vpc.kuber_private_subnet_a_id, module.kuber_fargate_vpc.kuber_private_subnet_b_id]
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  cluster_sg = module.kuber-cluster-sg.security-group-id
  alb_controller_policy_arn = module.kuber-cluster-role.kuber_load_balancer_controller_policy_arn
}
module "attach_policy" {
  source = "./modules/iam/eks/attach"
  prefix = var.prefix
  role_name = module.kubernetes-fargate.cluster_iam_role_name
  role_arn = module.kubernetes-fargate.cluster_iam_role_arn
}


#fargate custom module
module "kuber-fargate-execution-role" {
  source = "./modules/iam/eks/fargate"
  prefix = var.prefix
}

module "kuber-fargate" {
  source = "./modules/eks/fargate"
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  cluster_name = "${var.fargate_cluster_name}"
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  subnet_ids = [module.kuber_fargate_vpc.kuber_private_subnet_a_id, module.kuber_fargate_vpc.kuber_private_subnet_b_id]
  cluster_sg = module.kuber-cluster-sg.security-group-id
  node_sg = module.kuber-node-sg.security-group-id
  cluster_role_arn = module.kuber-cluster-role.kuber-cluster-role-arn
  fargate_execution_role_arn = module.kuber-fargate-execution-role.kuber-fargate-role-arn
   alb_controller_policy_arn = module.kuber-cluster-role.kuber_load_balancer_controller_policy_arn
}

*/
#####클러스터 생성 후 생성가능
/*
module "kubernetes_ec2_iam" {
  source = "./modules/iam/eks/ec2"
  prefix = var.prefix
}
module "kubernetes-fargate-iam" {
  source = "./modules/iam/eks/fargate"
  prefix = var.prefix
}
module "kubernetes-ec2-cluster" {
  source = "./modules/eks/ec2"
  prefix = "${var.prefix}-test"
  log_group = module.kubernetes-cloudwatch-log-group.log_group
  work_node_policy = module.kubernetes_ec2_iam.kuber-ec2-AmazonEKSWorkerNodePolicy
  eks_cni_policy = module.kubernetes_ec2_iam.kuber-ec2-AmazonEKS_CNI_Policy
  container_registry_readonly = module.kubernetes_ec2_iam.kuber-ec2-AmazonEC2ContainerRegistryReadOnly
  subnet_ids = [module.kuber_vpc.kuber_private_subnet_a_id, module.kuber_vpc.kuber_private_subnet_b_id]
  ec2_role_arn = module.kubernetes_ec2_iam.kuber-ec2-role-arn
}
*/
########## GitLab Codebuild ############
/*
module "gitlab_ecr" {
  source = "./modules/ecr/gitlab"
  prefix = "${var.prefix}-gitlab"
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "gitlab_codebuild_iam" {
  source = "./modules/iam/code/codebuild"
  account_num = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region
  repository_arn = module.gitlab_ecr.container-registry-arn
  bucket_name = module.code-bucket.bucket-name
  codebuild_name = "${var.prefix}-gitlab-project"
}

module "gitlab_buildmachine" {
  source = "./modules/code/codebuild/gitlab"
  prefix = "${var.prefix}-gitlab"
  aws_region = var.aws_region
  account_id = data.aws_caller_identity.current.account_id
  iam_arn = module.gitlab_codebuild_iam.iam-instance-arn
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  source_type = "NO_SOURCE"
  //source_location = module.code-repository.code-repository-clone-url-http
  codebuildbucket-name = module.code-bucket.bucket-name
  buildspec = var.buildspec
  git_token = var.gitlab_token
  git_url = var.gitlab_url
  bucket_name = module.code-bucket.bucket-name
  s3_path = var.codebuild_s3_path
  artifact_name = var.artifact_name
  architecture = "LINUX_CONTAINER"//var.x86_arch
  repo_name = module.gitlab_ecr.container-registry-name
}

module "cloudwatch_gitlab_webhook_lambda" {
  source = "./modules/cloudwatch/lambda"
  lambda_function_name = "cloudwatch-gitlab-webhook-lambda"
}

module "gitlab_webhook_lambda_iam"{
  source = "./modules/iam/webhooklambda"
  prefix = "${var.prefix}-gitlab-webhook"
  kms_arns = [data.aws_kms_key.kms_seoul_arn.arn]
}

module "gitlab_webhook_lambda_sg" {
  source = "./modules/security_group/lambda"
  prefix = "${var.prefix}_gitlab_webhook"
  vpc_id = module.vpc.vpc_id
}

module "gitlab_authorizer" {
   source = "./modules/lambda/gitlab_webhook"
   prefix = var.prefix
   name = "authorizer"
   iam_role = module.gitlab_webhook_lambda_iam.lambda-iam-instance-arn
   handler = "gitlab_webhook_lambda"
   runtime = "go1.x"
   arch = "x86_64"
   kms_key_arn = data.aws_kms_key.kms_seoul_arn.arn
   vpc_subnet_ids = [module.vpc.batch_subnet_a_id, module.vpc.batch_subnet_b_id]
   vpc_security_group_ids = [module.gitlab_webhook_lambda_sg.security-group-id]
   path_source_dir = "D:\\tech\\terraformproject\\example\\modules\\lambda\\gitlab_webhook\\lambdaapp\\"
   cw_log_group = module.cloudwatch_gitlab_webhook_lambda.loggroup-id
}

module "gitlab_webhook_lambda" {
   source = "./modules/lambda/gitlab_webhook"
   prefix = var.prefix
   name = "gitlab_webhook_lambda"
   iam_role = module.gitlab_webhook_lambda_iam.lambda-iam-instance-arn
   handler = "gitlab_webhook_lambda"
   runtime = "go1.x"
   arch = "x86_64"
   kms_key_arn = data.aws_kms_key.kms_seoul_arn.arn
   vpc_subnet_ids = [module.vpc.batch_subnet_a_id, module.vpc.batch_subnet_b_id]
   vpc_security_group_ids = [module.gitlab_webhook_lambda_sg.security-group-id]
   path_source_dir = "D:\\tech\\terraformproject\\example\\modules\\lambda\\gitlab_webhook\\lambdaapp\\"
   cw_log_group = module.cloudwatch_gitlab_webhook_lambda.loggroup-id
}

module "gitlab-apigateway" {
  source = "./modules/apigateway/ciwebhook"
  prefix = var.prefix
  gitlab_authorizer_invoke_arn = module.gitlab_authorizer.invoke_arn
  gitlab_webhook_lambda_invoke_arn = module.gitlab_webhook_lambda.invoke_arn
}
*/

############# SQS, SES, SNS, Cloudwatch Event Bridge ################
/*
module "sqs_lambda_iam"{
  source = "./modules/iam/lambda/sqslambda"
  prefix = var.prefix
  kms_arns = [data.aws_kms_key.kms_seoul_arn.arn]
}

module "sqslambda_sender" {
   source = "./modules/lambda/sqslambda"
   prefix = var.prefix
   name = "sqslambda-sender"
   iam_role = module.sqs_lambda_iam.lambda-iam-instance-arn
   handler = "sender"
   runtime = "go1.x"
   arch = "x86_64"
   kms_key_arn = data.aws_kms_key.kms_seoul_arn.arn
   path_source_dir = "D:\\tech\\terraformproject\\example\\modules\\lambda\\sqslambda\\"
   file_globs = ["sender"]
   s3_artifact_bucket = module.code-bucket.bucket-name
}

module "sqslambda_receiver" {
   source = "./modules/lambda/sqslambda"
   prefix = var.prefix
   name = "sqslambda-receiver"
   iam_role = module.sqs_lambda_iam.lambda-iam-instance-arn
   handler = "receiver"
   runtime = "go1.x"
   arch = "x86_64"
   kms_key_arn = data.aws_kms_key.kms_seoul_arn.arn
   path_source_dir = "D:\\tech\\terraformproject\\example\\modules\\lambda\\sqslambda\\"
   file_globs = ["receiver"]
   s3_artifact_bucket = module.code-bucket.bucket-name
}

module "sqs" {
  source = "./modules/sqs"
  prefix = var.prefix
  kms_keyid = data.aws_kms_key.kms_seoul_arn.key_id
}
*/

/*
module "sns_lambda_iam"{
  source = "./modules/iam/lambda/snslambda"
  prefix = var.prefix
  kms_arns = [data.aws_kms_key.kms_seoul_arn.arn]
}

module "snslambda_receiver" {
   source = "./modules/lambda/snslambda"
   prefix = var.prefix
   name = "snslambda"
   iam_role = module.sns_lambda_iam.lambda-iam-instance-arn
   handler = "receiver"
   runtime = "go1.x"
   arch = "x86_64"
   kms_key_arn = data.aws_kms_key.kms_seoul_arn.arn
   path_source_dir = "D:\\tech\\terraformproject\\example\\modules\\lambda\\snslambda\\"
   file_globs = ["snslambda"]
   s3_artifact_bucket = module.code-bucket.bucket-name
}


module "sns" {
  source = "./modules/sns"
  prefix = var.prefix
  account_id = data.aws_caller_identity.current.account_id
  kms_keyid = data.aws_kms_key.kms_seoul_arn.key_id
  lambda_arn = module.snslambda_receiver.lambda_arn
}
*/
/*
module "ses" {
  source = "./modules/ses"
  prefix = var.prefix
  source_email_address = "jhoh1075.link"
}
*/
/*
module "cloudwatch_rule" {
  source = "./modules/cloudwatch/rules"
  prefix = var.prefix
  function_name = module.batchlambda.lambda_name
  lambda_arn = module.batchlambda.lambda_arn
}
*/

##############Glue, Athena ##############
/*
module "glue_iam" {
  source = "./modules/iam/glue"
  prefix = var.prefix
}

module "glue" {
  source = "./modules/glue"
  prefix = var.prefix
  glue_iam_role_arn = module.glue_iam.iam-for-glue-arn
}

############ MSK #######################

module "msk-bucket" {
  source = "./modules/s3/msk"
  prefix = var.prefix
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}

module "msk-secretmanager" {
  source = "./modules/secretmanager"
  aws_region = var.aws_region
  prefix = "AmazonMSK_my"
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  secretname = "msk"

  secret_value = {
    username = "user"
    password = "pass"
  }
}
*/
/*

module "msk-connector-iam" {
  source = "./modules/iam/msk/connector"
  prefix = var.prefix
  aws_region = var.aws_region
  s3_arn = module.msk-bucket.bucket-arn
}

module "msk-sg" {
    source = "./modules/security_group/msk"
    prefix = var.prefix
    vpc_id = module.vpc.vpc_id
    msk_port = 2181
    ssh_port = var.ssh_port
    source_cidr_blocks_for_all_outbound_ipv4 = var.all_ipv4
    source_cidr_blocks_for_all_outbound_ipv6 = var.all_ipv6
    source_cidr_blocks_for_ssh_ipv4 = var.all_ipv4
    source_cidr_blocks_for_ssh_ipv6 = var.all_ipv6
    source_cidr_blocks_for_msk_ipv4 = var.all_ipv4
    source_cidr_blocks_for_msk_ipv6 = var.all_ipv6
}



module "msk-kinesis-cloudwatch-log-group" {
  source = "./modules/cloudwatch/kinesis"
  prefix = "msk-${var.prefix}"
  kinesis_name = "deliverystream"
}

module "msk-kinesis-iam" {
  source = "./modules/iam/kinesis"
  account_id = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region
  bucketname = module.msk-bucket.bucket-name
  stream_name = "msk-${var.prefix}-deliverystream"
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
}


module "msk-kinesis-deliverystream" {
  source = "./modules/kinesis"
  stream_name = "msk-${var.prefix}-deliverystream"
  iam_arn = module.msk-kinesis-iam.iam-arn
  bucket_arn = module.msk-bucket.bucket-arn
  kms_arn = data.aws_kms_key.kms_seoul_arn.arn
  cloudwatch_log_group_name = module.msk-kinesis-cloudwatch-log-group.loggroup-name
  cloudwatch_log_stream_name = module.msk-kinesis-cloudwatch-log-group.logstream-name
  s3_prefix = "cluster/"
}


module "msk_cluster" {
  source = "./modules/msk/cluster"
  prefix = var.prefix
  msk_version = var.msk_version
  firehose_name = module.msk-kinesis-deliverystream.kinesis-name
  log_group = module.msk-kinesis-cloudwatch-log-group.loggroup-name
  bucket_id = module.msk-bucket.bucket-id
  subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
  sg_id = module.msk-sg.security-group-id
  kms_key_arn = data.aws_kms_key.kms_seoul_arn.arn
  secret_arn = module.msk-secretmanager.secret_arn
}

module "msk_connector" {
  source = "./modules/msk/connector"
  prefix = var.prefix
  msk_version = var.msk_version
  bootstrap_tls = module.msk_cluster.bootstrap_brokers_sasl_iam
  bucket_id = module.msk-bucket.bucket-id
  bucket_arn = module.msk-bucket.bucket-arn
  subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
  sg_id = module.msk-sg.security-group-id
  connector_execution_iam_arn = module.msk-connector-iam.iam-instance-arn
}
*/


/*
# Kinesis에서 WAF 로그를 전달할 s3 생성 모듈
module "kinesis_s3" { 
  source = "./modules/s3"
  prefix = var.prefix
  user_tag = var.user_tag
  account_id = data.aws_caller_identity.current.account_id
}

module "waf_athena" {
  source = "./modules/athena"
  prefix = var.prefix
  aws_region = var.aws_region
  s3_bucket_id = module.kinesis_s3.bucket_id
  s3_bucket_name = module.kinesis_s3.bucket_name
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
  countrycode = ["RU", "CN"]
  kinesis_arn = module.waf_kinesis_deliverystream.kinesis_arn
  //kms_arn = data.aws_kms_key.kms_seoul_arn.arn                                      //KMS 필요시 주석 제거
}

#클라우드워치 대시보드
module "waf_cloudwatch_dashboard" {
  source = "./modules/cloudwatch/dashboard"
  prefix = var.prefix
  user_tag = var.user_tag
  aws_region = var.aws_region
}


#클라우드워치 알람
module "waf_cloudwatch_alarm" {
  source = "./modules/cloudwatch/alarm"
  prefix =  var.prefix
  user_tag = var.user_tag
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
  source = "./modules/sns"
  prefix = var.prefix
  account_id = data.aws_caller_identity.current.account_id
  lambda_arn = module.slack_lambda.lambda-arn
  lambda_name = module.slack_lambda.lambda-name
}
*/