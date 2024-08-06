
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.domain_name
  elasticsearch_version = "7.1"

  cluster_config {
    instance_type          = "t3.medium.search"
    zone_awareness_enabled = true
  }

  advanced_security_options {
    enabled                        = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "ccopenmanager"
      master_user_password = "Woongjin1234%"
    }
  }

  vpc_options {
    subnet_ids = [
      var.subnet_ids[0],
      var.subnet_ids[1],
    ]

    security_group_ids = var.elastic_search_sg_ids
  }

  node_to_node_encryption {
    enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 20
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.elasticsearch.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "es:*",
                "Principal": "*",
                "Effect": "Allow",
                "Resource": "arn:aws:es:${var.region}:${var.account_id}:domain/${var.domain_name}/*"
            }
        ]
    }
    CONFIG

  tags = {
    Domain = "${var.domain_name}"
    사용자 = "${var.user_tag}"
  }

  depends_on = [aws_iam_service_linked_role.es]
}


resource "aws_cloudwatch_log_group" "elasticsearch" {
  name = "elasticsearch"
}

data "aws_iam_policy_document" "elasticsearch_cw" {
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

resource "aws_cloudwatch_log_resource_policy" "elasticsearch_cw" {
  policy_name     = "${var.prefix}-es-cw-policy"
  policy_document = data.aws_iam_policy_document.elasticsearch_cw.json
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name = var.domain_name

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Condition": {
                "IpAddress": {"aws:SourceIp": "127.0.0.1/32"}
            },
            "Resource": "${aws_elasticsearch_domain.es.arn}/*"
        }
    ]
}
POLICIES
}