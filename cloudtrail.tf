resource "aws_cloudtrail" "main" {
  name                          = "cloudtrail-${data.aws_caller_identity.current.account_id}"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  depends_on = [
    aws_s3_bucket.cloudtrail,
    aws_s3_bucket_policy.cloudtrail
  ]
}
