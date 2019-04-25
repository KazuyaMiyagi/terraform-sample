resource "aws_ecs_task_definition" "laravel" {
  family       = "laravel"
  network_mode = "awsvpc"
  cpu          = "256"
  memory       = "512"
  container_definitions = templatefile("task-definitions/laravel.json.tpl", {
    aws_account = var.aws_account,
    aws_region  = var.aws_region,
    secrets     = merge(var.laravel_environments, var.laravel_secure_environments)
  })
  requires_compatibilities = [
    "FARGATE",
  ]
}
