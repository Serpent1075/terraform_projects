resource "aws_iam_instance_profile" "this" {
  name = "CodeBuild-Profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy" "autoscaling_codedeploy" {
  name = "CodeBuild-Policy"
  role = aws_iam_role.this.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-${var.aws_region}-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${var.repository_arn}"
            ],
            "Action": [
                "codecommit:GitPull"
            ]
        },
        {
            "Effect": "Allow",
            "Resource":"*",
            "Action": [
                "s3:PutObject",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:GetObjectVersion"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:${var.aws_region}:${var.account_num}:report-group/${var.codebuild_name}-*"
            ]
        },
        {
            "Effect": "Allow",
            "Resource":"*",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ],
            "Resource": "*",
            "Condition": {
              "StringEquals": {
                "kms:ViaService": "s3.${var.aws_region}.amazonaws.com",
                "kms:CallerAccount": "${var.account_num}"
              }
            }
        },
        {
            "Effect": "Allow", 
            "Action": [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role" "this" {
  name = "CodeBuild-Role"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "codebuild.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  )
}