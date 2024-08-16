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

module "vpc" {
    source = "./modules/vpc"
    prefix = var.prefix
    cidr_vpc = var.cidr_vpc
    az_a = var.az_a
    az_c = var.az_c
    cidr_pub_a = var.cidr_pub_a
    cidr_pub_c = var.cidr_pub_c
    cidr_pri_a = var.cidr_pri_a
    cidr_pri_c = var.cidr_pri_c
    //pub_nat_eip_private = var.pub_nat_eip_private
}