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

data "aws_iam_policy_document" "ecs_task_execution_role_assume_role_policy" {
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

resource "aws_iam_policy" "allow_ssm_get_parameters" {
  name   = "AllowSsmGetParameters"
  policy = data.aws_iam_policy_document.allow_ssm_get_parameters.json
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attached_policy_1" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attached_policy_2" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.allow_ssm_get_parameters.arn
}
