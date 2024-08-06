resource "aws_codebuild_project" "codebuild-project" {
  name          = "${var.prefix}-project"
  description   = "${var.prefix}_codebuild_project"
  build_timeout = "5"
  service_role  = var.iam_arn
  resource_access_role = var.iam_arn
  encryption_key = var.kms_arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "LOCAL"
    modes = [
      "LOCAL_DOCKER_LAYER_CACHE"
    ]
  }
   
#https://docs.aws.amazon.com/ko_kr/codebuild/latest/userguide/build-env-ref-available.html
#https://docs.aws.amazon.com/ko_kr/codebuild/latest/userguide/runtime-versions.html
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = var.architecture
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }
    environment_variable {
      name  = "GIT_BRANCH"
      value = "master"
    }
    environment_variable {
      name  = "GIT_COMMIT"
      value = "master"
    }
    environment_variable {
      name  = "GIT_URL"
      value = var.git_url
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.repo_name
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
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
    //location        = var.source_location
    //git_clone_depth = 1
    buildspec = file("${path.module}/buildspec.yaml")
    /*
    git_submodules_config {
      fetch_submodules = false
    }*/
  }


  source_version = "refs/heads/master"

  tags = {
    Environment = "Test"
  }
}
