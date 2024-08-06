
resource "aws_eks_addon" "kuber_coredns_addon" {
  cluster_name      = aws_eks_cluster.kuber_cluster.name
  addon_name        = "coredns"
  addon_version     = "v1.9.3-eksbuild.3" #e.g., previous version v1.8.7-eksbuild.2 and the new version is v1.8.7-eksbuild.3 v1.8.4-eksbuild.2
  resolve_conflicts = "OVERWRITE" #NONE PRESERVE
}

resource "aws_eks_addon" "kuber_proxy_addon" {
  cluster_name      = aws_eks_cluster.kuber_cluster.name
  addon_name        = "kube-proxy"
  addon_version     = "v1.24.10-eksbuild.2" #e.g., previous version v1.8.7-eksbuild.2 and the new version is v1.8.7-eksbuild.3
  resolve_conflicts = "OVERWRITE" #NONE PRESERVE
}

resource "aws_eks_addon" "kuber_vpc_cni_addon" {
  cluster_name      = aws_eks_cluster.kuber_cluster.name
  addon_name        = "vpc-cni"
  addon_version     = "v1.12.6-eksbuild.1" #e.g., previous version v1.8.7-eksbuild.2 and the new version is v1.8.7-eksbuild.3
  resolve_conflicts = "OVERWRITE" #NONE PRESERVE
}

resource "aws_eks_cluster" "kuber_cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  enabled_cluster_log_types = ["api","audit"]
  version = "1.24"
 
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access = true
    subnet_ids = var.subnet_ids
    security_group_ids = [var.cluster_sg]
    //cluster_security_group_id = var.cluster_sg
  }

/*
  encryption_config {
    provider {
      key_arn = var.kms_arn
    }
    resources = ["secrets"]
  }
*/
  kubernetes_network_config {
    service_ipv4_cidr = "10.100.0.0/16"
    ip_family = "ipv4"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    var.cluster_role_arn,
    aws_cloudwatch_log_group.kuber_log_group
  ]
 
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.kuber_cluster.name
  node_group_name = "${var.prefix}-node-group"
  node_role_arn   = var.ec2_role_arn
  subnet_ids      = var.subnet_ids
  
  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

#remote_access cannot be specified with a launch template
/*
  remote_access {
    ec2_ssh_key = var.ec2_ssh_key
  }
*/
  launch_template {
    id = var.lt_id
    version = "$Latest"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    var.cluster_role_arn,
    var.ec2_role_arn,
  ]
}

resource "aws_cloudwatch_log_group" "kuber_log_group" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  # ... potentially other configuration ...
}

data "tls_certificate" "kuber_identity" {
  url = aws_eks_cluster.kuber_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "openid_connect_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.kuber_identity.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.kuber_identity.url
}

data "aws_iam_policy_document" "kuber_iam_sa_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.openid_connect_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.openid_connect_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.openid_connect_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "iam_sa_role" {
  assume_role_policy = data.aws_iam_policy_document.kuber_iam_sa_assume_role_policy.json
  name               = "AmazonEKSLoadBalancerControllerEC2Role-${var.cluster_name}"
}


resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iam_sa_role.name
  policy_arn = var.alb_controller_policy_arn
}