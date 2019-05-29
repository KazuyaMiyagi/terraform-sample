locals {
  ecr_base_url           = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  deploy_image_tag       = "develop"
  standard_image         = "aws/codebuild/standard:2.0"
  laravel_migrator_image = "${local.ecr_base_url}/laravel:${local.deploy_image_tag}"
}

# container builder projects

resource "aws_codebuild_project" "laravel_container_builder" {
  name         = "laravel-container-builder"
  description  = "Container build project for laravel."
  service_role = aws_iam_role.codebuild.arn

  source {
    git_clone_depth     = 1
    insecure_ssl        = false
    location            = var.laravel_repository
    report_build_status = false
    type                = "BITBUCKET"
    buildspec           = file("./buildspec/laravel_container_builder.yml")
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = local.standard_image
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "LOCAL"
    modes = [
      "LOCAL_DOCKER_LAYER_CACHE",
      "LOCAL_SOURCE_CACHE"
    ]
  }

  depends_on = [
    "aws_iam_role.codebuild",
  ]
}

# migrator projects

resource "aws_codebuild_project" "laravel_migrator" {
  name         = "laravel-migrator"
  description  = "DB migrate project for laravel."
  service_role = aws_iam_role.codebuild.arn

  source {
    type = "NO_SOURCE"

    buildspec = file("./buildspec/laravel_migrator.yml")
  }

  environment {
    image                       = local.laravel_migrator_image
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    privileged_mode             = false
    image_pull_credentials_type = "SERVICE_ROLE"

    environment_variable {
      name  = "DB_CONNECTION"
      value = "/laravel/DB_CONNECTION"
      type  = "PARAMETER_STORE"
    }
  }

  vpc_config {
    vpc_id = aws_vpc.main.id
    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id
    ]
    security_group_ids = [
      aws_security_group.laravel.id
    ]
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "LOCAL"
    modes = [
      "LOCAL_DOCKER_LAYER_CACHE",
    ]
  }

  depends_on = [
    "aws_iam_role.codebuild",
  ]
}

# config file maker projects

resource "aws_codebuild_project" "laravel_config_file_maker" {
  name         = "laravel-config-file-maker"
  description  = "Make config file project for laravel."
  service_role = aws_iam_role.codebuild.arn

  source {
    type = "CODEPIPELINE"

    buildspec = <<BUILDSPEC
version: 0.2

phases:
  install:
    runtime-versions:
      docker: 18
  build:
    commands:
      - IMAGE_URI=$(jq '.ImageURI' < imageDetail.json)
      - |
        cat << EOF > imagedefinitions.json
        [
          {
            "name": "laravel",
            "imageUri": $${IMAGE_URI}
          },
          {
            "name": "laravel-scheduler",
            "imageUri": $${IMAGE_URI}
          },
          {
            "name": "laravel-worker",
            "imageUri": $${IMAGE_URI}
          }
        ]
        EOF
artifacts:
  files: imagedefinitions.json
BUILDSPEC
  }

  environment {
    image = local.standard_image
    type = "LINUX_CONTAINER"
    compute_type = "BUILD_GENERAL1_SMALL"
    privileged_mode = false
    image_pull_credentials_type = "CODEBUILD"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "NO_CACHE"
  }

  depends_on = [
    "aws_iam_role.codebuild",
  ]
}
