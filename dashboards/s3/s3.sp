locals {
  s3_common_tags = {
    service = "AWS/S3"
  }
}

category "aws_s3_access_point" {
  title = "S3 Access Point"
  color = local.storage_color
  icon  = "text:AP"
}

category "aws_s3_bucket" {
  title = "S3 Bucket"
  href  = "/aws_insights.dashboard.aws_s3_bucket_detail?input.bucket_arn={{.properties.'ARN' | @uri}}"
  icon  = "archive-box"
  color = local.storage_color
}
