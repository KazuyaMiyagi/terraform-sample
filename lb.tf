resource "aws_lb" "laravel" {
  name               = "laravel"
  load_balancer_type = "application"
  internal           = false

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id
  ]

  security_groups = [
    aws_security_group.elb.id
  ]

  access_logs {
    bucket  = aws_s3_bucket.lb.id
    enabled = true
  }
}

resource "aws_lb_listener" "laravel_http" {
  load_balancer_arn = "${aws_lb.laravel.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.laravel.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "laravel" {
  name        = "laravel"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path    = "/login"
    matcher = "200"
  }

  depends_on = [
    aws_lb.laravel
  ]
}
