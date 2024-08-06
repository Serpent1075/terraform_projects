#https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

locals {
  name            = "${var.cluster_name}"

  cluster_version = "1.23"
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
    /*
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    */
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni    = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = var.kms_arn
    resources        = ["secrets"]  
  }]

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  control_plane_subnet_ids  = var.subnet_ids
  cluster_security_group_id = var.cluster_sg
  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false
  create_cloudwatch_log_group = false
  //create_aws_auth_configmap = true
  //manage_aws_auth_configmap = true

 

  fargate_profiles = {
    service = {
      name = "${var.prefix}-fargate-profile"
      selectors = [
        {
          namespace = "${var.prefix}"
          labels = {
            app = "backend"
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
    
    default = {
      name = "default"
      selectors = [
        { namespace = "default" }
      ]
    }

    backend = {
      name = "backend"
      selectors = [
        { namespace = "backend" }
      ]
    }

    application = {
      name = "app-wildcard"
      selectors = [
        { namespace = "app-*" }
      ]
    }
  }
  
  tags = local.tags
}

data "aws_iam_policy_document" "kuber_iam_sa_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "iam_sa_role" {
  assume_role_policy = data.aws_iam_policy_document.kuber_iam_sa_assume_role_policy.json
  name               = "AmazonEKSLoadBalancerControllerFargateRole-${var.cluster_name}"
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iam_sa_role.name
  policy_arn = var.alb_controller_policy_arn
}

##############LB Controller##########################
#https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html
