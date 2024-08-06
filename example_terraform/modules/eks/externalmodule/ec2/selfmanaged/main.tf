#https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

locals {
  name            = "${var.prefix}-kuber"
  cluster_version = "1.24"
  region          = var.aws_region

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
  }

  cluster_encryption_config = [{
    provider_key_arn = var.kms_arn
    resources        = ["secrets"]
  }]

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  cluster_security_group_id = var.cluster_sg
  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false
  
  fargate_profiles = {
    service = {
      name = "${var.prefix}-fargate-profile"
      selectors = [
        {
          namespace = "${var.prefix}"
          labels = {
            Application = "backend"
          }
        },
        {
          namespace = "app-*"
          labels = {
            Application = "app-wildcard"
          }
        }
      ]

      # Using specific subnets instead of the subnets supplied for the cluster itself
      subnet_ids = var.subnet_ids

      tags = {
        Owner = "secondary"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }

    kube_system = {
      name = "kube-system"
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

  tags = local.tags
}
