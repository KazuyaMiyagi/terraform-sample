resource "aws_codepipeline" "laravel_deploy_pipeline" {
  name     = "laravel-deploy-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.developer_tools.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name      = "Source"
      category  = "Source"
      owner     = "AWS"
      provider  = "ECR"
      run_order = "1"
      version   = "1"

      configuration = {
        ImageTag       = local.deploy_image_tag
        RepositoryName = aws_ecr_repository.laravel.name
      }

      output_artifacts = [
        "SourceArtifact",
      ]
    }
  }

  stage {
    name = "Deploy"

    action {
      name      = "Configure"
      category  = "Build"
      owner     = "AWS"
      provider  = "CodeBuild"
      run_order = "1"
      version   = "1"

      configuration = {
        ProjectName = aws_codebuild_project.laravel_config_file_maker.id
      }

      input_artifacts = [
        "SourceArtifact",
      ]

      output_artifacts = [
        "ConfigArtifact",
      ]

    }

    action {
      name      = "Migrate"
      category  = "Build"
      owner     = "AWS"
      provider  = "CodeBuild"
      run_order = "1"
      version   = "1"

      configuration = {
        ProjectName = aws_codebuild_project.laravel_migrator.id
      }

      input_artifacts = [
        "SourceArtifact",
      ]
    }

    action {
      name      = "Deploy"
      category  = "Deploy"
      owner     = "AWS"
      provider  = "ECS"
      run_order = "2"
      version   = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.laravel.name
        FileName    = "imagedefinitions.json"
        ServiceName = aws_ecs_service.laravel.name
      }

      input_artifacts = [
        "ConfigArtifact",
      ]
    }
  }

  depends_on = [
    "aws_iam_role.codepipeline",
    "aws_codebuild_project.laravel_config_file_maker"
  ]
}
