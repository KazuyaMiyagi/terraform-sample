resource "aws_ecs_cluster" "laravel" {
  name = "laravel"
}

resource "aws_ecs_task_definition" "laravel" {
  family             = "laravel"
  network_mode       = "awsvpc"
  cpu                = "256"
  memory             = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = templatefile("templates/laravel.json.tmpl", {
    aws_account    = data.aws_caller_identity.current.account_id,
    aws_region     = data.aws_region.current.name,
    repository_url = aws_ecr_repository.laravel.repository_url,
    secrets        = merge(var.laravel_environments, var.laravel_secure_environments)
  })
  requires_compatibilities = [
    "FARGATE",
  ]
}
