resource "aws_cloudwatch_log_group" "laravel" {
  name = "/ecs/laravel"
}

resource "aws_cloudwatch_event_rule" "laravel_deploy_pipeline" {
  name          = "laravel-deploy-pipeline-rule"
  description   = "Detect ECR push event and start pipeline."
  event_pattern = <<PATTERN
{
  "source": [
    "aws.ecr"
  ],
  "detail": {
    "eventName": [
      "PutImage"
    ],
    "requestParameters": {
      "repositoryName": [
        "${aws_ecr_repository.laravel.name}"
      ],
      "imageTag": [
        "${local.deploy_image_tag}"
      ]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "laravel_deploy_pipeline" {
  rule = aws_cloudwatch_event_rule.laravel_deploy_pipeline.name
  arn = aws_codepipeline.laravel_deploy_pipeline.arn
  role_arn = aws_iam_role.start_pipeline.arn
}
