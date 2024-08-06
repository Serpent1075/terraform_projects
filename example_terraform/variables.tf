
variable "prefix" {
  description = "prefix of resource name"
  type = string
  default = "jhoh-tf"
}
variable "client_name" {
  description = "prefix of resource name"
  type = string
  default = "hundai-surff-tf"
}
variable "username" {
  description = "user name of aws account"
  type = string
  default = "jhoh"
}
variable "github_token" {
  description = "Github Token"
  type = string
  default = ""
}
variable "gitlab_token" {
  description = "GitLab Toekn"
  type = string
  default = ""
}
variable "gitlab_url" {
  description = "GitLab URL"
  type = string
  default = ""
}
variable "build_behavior" {
  description = "Build Behavior"
  type = string
  default = "production"
}
############################## VPC ###################################
variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "ap-northeast-2"
}
variable "access_key"{
  description = "The access key in which all resources will be created"
  type = string
  sensitive = true
}
variable "secret_key" {
  description = "The secret key in which all resources will be created"
  type = string
  sensitive = true
}
variable "az_a" {
  type = string
  default = "ap-northeast-2a"
}
variable "az_b" {
  type = string
  default = "ap-northeast-2b"
}
variable "az_c" {
  type = string
  default = "ap-northeast-2c"
}
variable "cidr_vpc" {
  type = string
  default = "172.20.0.0/16"
}
variable "cidr_pub_a" {
  type = string
  default = "172.20.4.0/22"
}
variable "cidr_pub_b" {
  type = string
  default = "172.20.8.0/22"
}
variable "cidr_pri_a" {
  type = string
  default = "172.20.12.0/22"
}
variable "cidr_pri_b" {
  type = string
  default = "172.20.16.0/22"
}
variable "cidr_batch_a" {
  type = string
  default = "172.20.20.0/22"
}
variable "cidr_batch_b" {
  type = string
  default = "172.20.24.0/22"
}
variable "pub_nat_eip_private" {
  type = string
  default = "172.20.4.5"
}
##############################EKS VPC ##########################
variable "fargate_cluster_name" {
  type = string
  default = "jhoh-tf-fargate-kuber"
}
variable "cidr_fargate_kuber_pub_a" {
  type = string
  default = "172.20.28.0/22"
}
variable "cidr_fargate_kuber_pub_b" {
  type = string
  default = "172.20.32.0/22"
}
variable "cidr_fargate_kuber_pub_c" {
  type = string
  default = "172.20.36.0/22"
}
variable "cidr_fargate_kuber_pri_a" {
  type = string
  default = "172.20.40.0/22"
}
variable "cidr_fargate_kuber_pri_b" {
  type = string
  default = "172.20.44.0/22"
}
variable "cidr_fargate_kuber_pri_c" {
  type = string
  default = "172.20.48.0/22"
}
variable "pub_fargate_kuber_nat_eip_private" {
  type = string
  default = "172.20.28.5"
}
variable "ec2_cluster_name" {
  type = string
  default = "jhoh-tf-ec2-kuber"
}
variable "cidr_ec2_kuber_pub_a" {
  type = string
  default = "172.20.52.0/22"
}
variable "cidr_ec2_kuber_pub_b" {
  type = string
  default = "172.20.56.0/22"
}
variable "cidr_ec2_kuber_pub_c" {
  type = string
  default = "172.20.60.0/22"
}
variable "cidr_ec2_kuber_pri_a" {
  type = string
  default = "172.20.64.0/22"
}
variable "cidr_ec2_kuber_pri_b" {
  type = string
  default = "172.20.68.0/22"
}
variable "cidr_ec2_kuber_pri_c" {
  type = string
  default = "172.20.72.0/22"
}
variable "pub_ec2_kuber_nat_eip_private" {
  type = string
  default = "172.20.52.5"
}
############################## WEB API SG ###################################
variable "webapi_port" {
  description = "webapi port"
  type = number
  default = 3010
}
variable "ssh_port" {
  description = "ssh port"
  type = number
  default = 22
}
variable "all_ipv4"{
  description = "source cidr block for all outbound traffic of ipv4"
  type = list(string)
  default = ["0.0.0.0/0"]
}
variable "all_ipv6"{
  description = "source cidr block for all outbound traffic of ipv6"
  type = list(string)
  default = ["::/0"]
}
############################## WEB API Launch Template###################################
variable "webapi-instance-type" {
  description = "Web API Instance Type"
  type = string
  default = "t4g.small"
}
variable "webapi-key-name" {
  description = "Web API ssh key pair name"
  type = string
  default = "bastion_host"
}
variable "webapi-ami-id" {
  description = "Web API AMI Id"
  type = string
  default = "ami-05d1b0b938144501e"
}
variable "webapi-standalone-instance-type" {
  description = "Web API Instance Type"
  type = string
  default = "t4g.small"
}
variable "webapi-standalone-ami-id" {
  description = "Web API AMI Id"
  type = string
  default = "ami-0d4a2b7c3a596df97"
}

########################### Load Balancer ################################################
variable "domain_address" {
  description = "Domain Address"
  type = string
  default = "jhoh1075.link"
}
########################### KMS ###########################################################
variable "kms_key_name" {
  description = "KMS Key Name"
  type = string
  default = "jhoh-test-kms"
}
########################## Parameter Store ###############################################
variable "ps_cw_config_standalone_name"{
  description = "Parameter Store Cloudwatch Config Name"
  type = string
  default = "AmazonCloudWatch-jhoh-standalone"
}

variable "ps_cw_config_name"{
  description = "Parameter Store Cloudwatch Config Name"
  type = string
  default = "AmazonCloudWatch-jhoh-prod"
}
########################## Redis ######################
variable "redisport" {
  description = "Redis Port"
  type = number
  default = 6379
}
variable "maintenance_date" {
  description = "Maintenance Date"
  type = string
  default = "tue:18:30-tue:19:30"
}
##########################  RDS #######################
variable "database_name" {
  description = "Database Name"
  type = string
  default = "urmydb"
}

variable "psqlport" {
  description = "Postgresql Port"
  type = number
  default = 5432
}
variable "psqlusername" {
  description = "Username"
  type = string
  default = "urmyadmin"
}
########################## Mongo ###############################
variable "mongourl" {
  description = "Mongodb URL"
  type = string
  default = "http://localhost:27017"
}

########################### CI/CD #########################################################
variable "buildspec" {
    description = "Build Specification for Code Build"
    type = string
    default = "buildspec.yml"
}

variable "codebuild_artifacts_s3_path" {
  description = "CodeBuild Artifact path"
  type = string
  default = "prod"
}

variable "artifact_name" {
  description = "An Artifact Name"
  type = string
  default = "myapp.zip"
}

variable "x86_arch" {
  description = "x86_64 architecture"
  type = string
  default = "LINUX_CONTAINER"
}

variable "arm_arch" {
  description = "ARM architecture"
  type = string
  default = "ARM_CONTAINER"
}

######################## Batch ###########################
variable "secret_value" {
  default = {
    key1 = "value1"
    key2 = "value2"
  }

  type = map(string)
}

##################### gitlab cicd ####################

variable "codebuild_s3_path" {
  description = "CodeBuild Artifact path"
  type = string
  default = "gitlab_dev"
}

################ MSK #################################

variable "msk_version" {
  description = "MSK Version"
  type = string
  default = "3.2.0"
}