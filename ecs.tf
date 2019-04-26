resource "aws_ecs_cluster" "laravel-cluster" {
  name = "laravel-cluster"
}

resource "aws_ecs_task_definition" "laravel" {
  family             = "laravel"
  network_mode       = "awsvpc"
  cpu                = "256"
  memory             = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = templatefile("templates/laravel.json.tmpl", {
    aws_account = var.aws_account,
    aws_region  = var.aws_region,
    secrets     = merge(var.laravel_environments, var.laravel_secure_environments)
  })
  requires_compatibilities = [
    "FARGATE",
  ]
}
