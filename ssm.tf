resource "aws_ssm_parameter" "laravel_parameters" {
  count = length(var.laravel_environments)
  name  = "/laravel/${element(keys(var.laravel_environments), count.index)}"
  type  = "String"
  value = element(values(var.laravel_environments), count.index)
}

resource "aws_ssm_parameter" "laravel_secure_parameters" {
  count = length(var.laravel_secure_environments)
  name  = "/laravel/${element(keys(var.laravel_secure_environments), count.index)}"
  type  = "SecureString"
  value = element(values(var.laravel_secure_environments), count.index)
}
