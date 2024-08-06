#https://devblog.kakaostyle.com/ko/2022-03-31-3-build-eks-cluster-with-terraform/
#https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs
#https://registry.terraform.io/modules/iplabs/alb-ingress-controller/kubernetes/latest
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = local.cluster_name
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cloudwatch_log_group_retention_in_days = 1

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "kube-system"
        },
        {
          namespace = "default"
        }
      ]
    }
  }
}

locals {
  lb_controller_iam_role_name        = "inhouse-eks-aws-lb-ctrl"
  lb_controller_service_account_name = "aws-load-balancer-controller"
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

module "lb_controller_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = true

  role_name        = local.lb_controller_iam_role_name
  role_path        = "/"
  role_description = "Used by AWS Load Balancer Controller for EKS"

  role_permissions_boundary_arn = ""

  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:${local.lb_controller_service_account_name}"
  ]
  oidc_fully_qualified_audiences = [
    "sts.amazonaws.com"
  ]
}

data "http" "iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.0/docs/install/iam_policy.json"
}

resource "aws_iam_role_policy" "controller" {
  name_prefix = "AWSLoadBalancerControllerIAMPolicy"
  policy      = data.http.iam_policy.body
  role        = module.lb_controller_role.iam_role_name
}

resource "helm_release" "release" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"

  dynamic "set" {
    for_each = {
      "clusterName"           = module.eks.cluster_id
      "serviceAccount.create" = "true"
      "serviceAccount.name"   = local.lb_controller_service_account_name
      "region"                = "ap-northeast-2"
      "vpcId"                 = module.vpc.vpc_id
      "image.repository"      = "708595888134.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller"

      "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = module.lb_controller_role.iam_role_arn
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}