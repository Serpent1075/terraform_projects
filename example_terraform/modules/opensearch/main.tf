#https://docs.aws.amazon.com/ko_kr/opensearch-service/latest/developerguide/cognito-auth.html
resource "aws_opensearch_domain" "opensearch" {
  domain_name    = var.domain
  engine_version = "OpenSearch_2.5"

  cluster_config {
    instance_type          = "t3.medium.search"
    instance_count = 1
    zone_awareness_enabled = true
  }

  advanced_security_options {
    enabled                        = false
    anonymous_auth_enabled         = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "ccopenmanager"
      master_user_password = "Woongjin1234%"
    }
  }


  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  //  custom_endpoint_certificate_arn = var.acm_arn
   // custom_endpoint_enabled = true
   // custom_endpoint = var.domain_address
  }

/*
  cognito_options {
    enabled          = true
    user_pool_id     = var.user_pool_id
    identity_pool_id = var.identity_pool_id
    role_arn         = "arn:aws:iam::${var.account_id}:role/service-role/CognitoAccessForAmazonOpenSearch"
  }
*/

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    subnet_ids = [
      var.subnet_ids[0],
      var.subnet_ids[1],
      
    ]

    security_group_ids = var.opensearch_sg
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 20
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.opensearch.json

  tags = {
    Domain = "${var.domain}"
    사용자 = "${var.user_tag}"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }

  //depends_on = [aws_iam_service_linked_role.opensearch]
}


data "aws_iam_policy_document" "opensearch" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:${var.region}:${var.account_id}:domain/${var.domain}/*"]
  }
}

data "aws_iam_policy_document" "opensearch_log" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }

    actions = [
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
      "logs:CreateLogStream",
    ]

    resources = ["arn:aws:logs:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch_log" {
  policy_name     = "${var.prefix}-opensearch-log-policy"
  policy_document = data.aws_iam_policy_document.opensearch_log.json
}

/*
resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchservice.amazonaws.com"
 
}
*/
/*
resource "aws_cognito_managed_user_pool_client" "opensearch" {
  name_prefix  = "AmazonOpenSearchService-${var.prefix}"
  user_pool_id = var.user_pool_id

  depends_on = [
    aws_opensearch_domain.opensearch
  ]
}*/