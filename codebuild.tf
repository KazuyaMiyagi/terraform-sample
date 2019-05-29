locals {
  ecr_base_url         = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  deploy_image_tag     = "develop"
  standard_image       = "aws/codebuild/standard:2.0"
  laravel_deploy_image = "${local.ecr_base_url}/laravel:${local.deploy_image_tag}"
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
    buildspec           = <<BUILDSPEC
version: 0.2

##
# These environment variables are set automatically.
# - AWS_REGION
# - CODEBUILD_BUILD_ARN
# For details, please see here.
# https://docs.aws.amazon.com/en_us/codebuild/latest/userguide/build-env-ref-env-vars.html
env:
  variables:
    DOCKER_BUILDKIT: 1
    ECR_REPOSITORY_NAME: "laravel"
    TARGET_STAGE : "release"
phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      # CODEBUILD_BUILD_ARN: The Amazon Resource Name (ARN) of the build (for example, arn:aws:codebuild:region-ID:account-ID:build/codebuild-demo-project:b1e6661e-e4f2-4156-9ab9-82a19EXAMPLE).
      - AWS_ACCOUNT_ID=$(echo $${CODEBUILD_BUILD_ARN} | cut -d ':' -f 5)
      # git describe --all for example heads/branch-name or tags/tag-name
      - IMAGE_TAG=$${IMAGE_TAG:-$(git describe --all | cut -d '/' -f 2)}
      - $(aws ecr get-login --no-include-email --region $${AWS_REGION})
      - if [ $IMAGE_TAG = "develop" ] ; then TARGET_STAGE="develop" ; fi
  build:
    commands:
      - docker build --target $${TARGET_STAGE} -t $${AWS_ACCOUNT_ID}.dkr.ecr.$${AWS_REGION}.amazonaws.com/$${ECR_REPOSITORY_NAME}:$${IMAGE_TAG} .
  post_build:
    commands:
      - docker push $${AWS_ACCOUNT_ID}.dkr.ecr.$${AWS_REGION}.amazonaws.com/$${ECR_REPOSITORY_NAME}:$${IMAGE_TAG}
BUILDSPEC
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = local.standard_image
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true
    type = "LINUX_CONTAINER"
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
  name = "laravel-migrator"
  description = "DB migrate project for laravel."
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
