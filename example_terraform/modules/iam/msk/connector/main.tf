
resource "aws_iam_role_policy" "msk_policy" {
  name = "MSK-${var.prefix}-policy"
  role = aws_iam_role.msk_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListAllMyBuckets"
        ],
        "Resource": "arn:aws:s3:::*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:DeleteObject"
        ],
        "Resource": "${var.s3_arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role" "msk_role" {
  name = "MSK-Role-${var.prefix}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "kafkaconnect.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  )
}