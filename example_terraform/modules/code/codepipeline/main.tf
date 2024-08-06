resource "aws_codepipeline" "codepipeline" {
  name     = "${var.prefix}-codepipeline"
  role_arn = var.iam_arn


  artifact_store {
    location = var.code_bucket
    type     = "S3"

    encryption_key {
      id   = var.kms_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      region = var.aws_region
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = var.codecommit_id
        BranchName       = "master"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      region = var.aws_region

      configuration = {
        ProjectName = var.codebuild_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      output_artifacts = [""]
      version         = "1"
      region = var.aws_region

      configuration = {
        ApplicationName     = var.codedeploy_app_name,
        DeploymentGroupName   = var.codedeploy_deploy_group_name
      }
    }
  }
}