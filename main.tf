# https://www.terraform.io/docs/providers/aws/d/caller_identity.html
# account data
data "aws_caller_identity" "current" {}

# https://www.terraform.io/docs/providers/aws/d/region.html
# region data
data "aws_region" "current" {}

# https://www.terraform.io/docs/providers/aws/d/availability_zones.html
# availability_zones data
data "aws_availability_zones" "available" {}

# https://www.terraform.io/docs/providers/aws/d/elb_service_account.html
# elb service account data
data "aws_elb_service_account" "main" {}
