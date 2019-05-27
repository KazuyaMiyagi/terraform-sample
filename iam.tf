resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_execution_role_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attached_policy_1" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attached_policy_2" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.allow_ssm_get_parameters.arn
}

resource "aws_iam_policy" "allow_ssm_get_parameters" {
  name   = "AllowSsmGetParameters"
  policy = data.aws_iam_policy_document.allow_ssm_get_parameters.json
}

data "aws_iam_policy_document" "allow_ssm_get_parameters" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "*"
    ]
  }
}

# CodeBuild IAM

resource "aws_iam_role" "codebuild" {
  name               = "CodeBuildExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "codebuild.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_attached_policy_1" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "codebuild_attached_policy_2" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "${aws_iam_policy.codebuild_base.arn}"
}

resource "aws_iam_policy" "codebuild_base" {
  name   = "CodeBuildBasePolicy"
  policy = data.aws_iam_policy_document.codebuild_base.json
}

data "aws_iam_policy_document" "codebuild_base" {
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*",
    ]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "${aws_s3_bucket.developer_tools.arn}",
      "${aws_s3_bucket.developer_tools.arn}/*",
    ]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_attached_policy_3" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.allow_ssm_get_parameters.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_attached_policy_4" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild_vpc.arn
}

resource "aws_iam_policy" "codebuild_vpc" {
  name   = "CodeBuildVpcPolicy"
  policy = data.aws_iam_policy_document.codebuild_vpc.json
}

data "aws_iam_policy_document" "codebuild_vpc" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
    ]

    actions = [
      "ec2:CreateNetworkInterfacePermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"

      values = [
        "codebuild.amazonaws.com",
      ]
    }
  }
}

# CodePipeline IAM

resource "aws_iam_role" "codepipeline" {
  name               = "CodepipelineExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "codepipeline.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codepipeline_attached_policy_1" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_iam_policy" "codepipeline" {
  name   = "CodePipelinePolicy"
  policy = data.aws_iam_policy_document.codepipeline.json
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/*",
    ]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      aws_s3_bucket.developer_tools.arn,
      "${aws_s3_bucket.developer_tools.arn}/*",
    ]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
  }
}
