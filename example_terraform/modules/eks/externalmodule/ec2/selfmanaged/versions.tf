terraform {
  required_version = ">= 1.2.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}