resource "aws_vpc_endpoint" "ecrapi" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    var.endpoint_sg_id,
  ]

  subnet_ids = var.subnet_ids

  private_dns_enabled = true

   tags = {
    Name = "${var.prefix}-ecrapi-endpoint"
  }
}

resource "aws_vpc_endpoint_policy" "ecrapi_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.ecrapi.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAll",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "${var.ecs_iam_arn}"
          ]
        },
        "Action" : [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
			    "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ],
        "Resource" : "*"
      }
    ]
  })
}



##############################################################
#Farget 1.4.0 버전을 사용할 경우에도 필요
resource "aws_vpc_endpoint" "ecrdrk" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    var.endpoint_sg_id,
  ]

  subnet_ids = var.subnet_ids

  private_dns_enabled = true

   tags = {
    Name = "${var.prefix}-ecrdkr-endpoint"
  }
}

resource "aws_vpc_endpoint_policy" "ecrdrk_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.ecrdrk.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAll",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "${var.ecs_iam_arn}"
          ]
        },
        "Action" : [
          "ecr:BatchGetImage",
			    "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ],
        "Resource" : "*"
      }
    ]
  })
}


##############################################################

resource "aws_vpc_endpoint" "secretmanager" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    var.endpoint_sg_id,
  ]

  subnet_ids = var.subnet_ids

  private_dns_enabled = true

   tags = {
    Name = "${var.prefix}-secretmanager-endpoint"
  }
}


##############################################################

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    var.endpoint_sg_id,
  ]

  subnet_ids = var.subnet_ids

  private_dns_enabled = true

   tags = {
    Name = "${var.prefix}-logs-endpoint"
  }
}


##############################################################
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

   tags = {
    Name = "${var.prefix}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_rt_associate" {
  route_table_id  = var.route_table_id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

