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

resource "aws_ecs_service" "laravel" {
  name                               = "laravel"
  cluster                            = aws_ecs_cluster.laravel.arn
  task_definition                    = aws_ecs_task_definition.laravel.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets = [
      aws_subnet.public_0.id,
      aws_subnet.public_1.id
    ]
    security_groups = [
      aws_security_group.laravel.id
    ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.laravel.arn
    container_name   = "laravel"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [
      "desired_count",
      "task_definition"
    ]
  }

  depends_on = [
    aws_lb.laravel
  ]
}
