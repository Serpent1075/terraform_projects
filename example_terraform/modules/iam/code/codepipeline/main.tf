resource "aws_iam_role" "codepipeline_role" {
  name = "CodePipeline-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "CodePipeline-Policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${var.code_bucket_arn}",
        "${var.code_bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:GetCommit",
        "codecommit:GetRepositoryTriggers",
        "codecommit:GetObjectIdentifier",
        "codecommit:GetFolder",
        "codecommit:GetFile",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:GetRepository",
        "codecommit:GetBranch",
        "codecommit:UploadArchive"
      ],
      "Resource": "${var.codecommit_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "arn:aws:codedeploy:${var.aws_region}:${var.account_num}:*"
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
    }      
  ]
}
EOF
}