
resource "aws_codebuild_source_credential" "github-credential" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}
resource "aws_codebuild_project" "codebuild-project" {
  name          = "${var.prefix}-project"
  description   = "${var.prefix}_codebuild_project"
  build_timeout = "5"
  service_role  = var.iam_arn
  resource_access_role = var.iam_arn
  encryption_key = var.kms_arn

  artifacts {
    type = "S3"
    packaging = "ZIP"
    namespace_type = "NONE"
    location = var.bucket_name
    path = var.s3_path
    name  = var.artifact_name
  }

  cache {
    type     = "S3"
    location = var.codebuildbucket-name
  }
  
#https://docs.aws.amazon.com/ko_kr/codebuild/latest/userguide/build-env-ref-available.html
#https://docs.aws.amazon.com/ko_kr/codebuild/latest/userguide/runtime-versions.html
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = var.architecture
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.prefix}-codebuild"
      stream_name = "${var.prefix}"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${var.codebuildbucket-name}/build-log"
    }
  }

  source {
    type            = var.source_type
    location        = var.source_location
    git_clone_depth = 1
    buildspec = var.buildspec

    git_submodules_config {
      fetch_submodules = false
    }
  }

  source_version = "refs/heads/master"

  tags = {
    Environment = "Test"
  }
}

