resource "aws_ecr_repository" "laravel" {
  name = "laravel"
}

resource "aws_ecr_lifecycle_policy" "laravel" {
  repository = aws_ecr_repository.laravel.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete untagged images",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
