locals {
  bitbucket_account      = "KazuyaMiyagi"
  ecr_base_url           = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  migrator_image_tag     = "master"
  standard_image         = "aws/codebuild/standard:2.0"
  laravel_migrator_image = "${local.ecr_base_url}/laravel:${local.migrator_image_tag}"
  laravel_repository     = "https://${local.bitbucket_account}@bitbucket.org/KazuyaMiyagi/test.git"
}

# container builder projects

resource "aws_codebuild_project" "laravel_container_builder" {
  name         = "laravel-container-builder"
  description  = "Container build project for laravel."
  service_role = aws_iam_role.codebuild.arn

  source {
    buildspec           = ""
    git_clone_depth     = 1
    insecure_ssl        = false
    location            = local.laravel_repository
    report_build_status = false
    type                = "BITBUCKET"
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

    buildspec = <<BUILDSPEC
version: 0.2

phases:
  build:
    commands:
      - cd /usr/src/app
      - php artisan migrate --force
BUILDSPEC
  }

  environment {
    image = local.laravel_migrator_image
    type = "LINUX_CONTAINER"
    compute_type = "BUILD_GENERAL1_SMALL"
    privileged_mode = false
    image_pull_credentials_type = "SERVICE_ROLE"

    environment_variable {
      name = "DB_CONNECTION"
      value = "/laravel/DB_CONNECTION"
      type = "PARAMETER_STORE"
    }

    environment_variable {
      name = "DB_HOST"
      value = "/laravel/DB_HOST"
      type = "PARAMETER_STORE"
    }

    environment_variable {
      name = "DB_PORT"
      value = "/laravel/DB_PORT"
      type = "PARAMETER_STORE"
    }

    environment_variable {
      name = "DB_DATABASE"
      value = "/laravel/DB_DATABASE"
      type = "PARAMETER_STORE"
    }

    environment_variable {
      name = "DB_USERNAME"
      value = "/laravel/DB_USERNAME"
      type = "PARAMETER_STORE"
    }

    environment_variable {
      name = "DB_PASSWORD"
      value = "/laravel/DB_PASSWORD"
      type = "PARAMETER_STORE"
    }
  }

  vpc_config {
    vpc_id = aws_vpc.main.id
    subnets = [
      aws_subnet.public_0.id,
      aws_subnet.public_1.id
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
