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
    Name = "${var.prefix}-kuber-ecrapi-endpoint"
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
            "${var.list_iam_arn[0]}",
            "${var.list_iam_arn[1]}",
            "${var.list_iam_arn[2]}"
            
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

  depends_on = [aws_vpc_endpoint.ecrapi]
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
    Name = "${var.prefix}-kuber-ecrdkr-endpoint"
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
            "${var.list_iam_arn[0]}",
            "${var.list_iam_arn[1]}"
            //"${var.list_iam_arn[2]}"
            
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
