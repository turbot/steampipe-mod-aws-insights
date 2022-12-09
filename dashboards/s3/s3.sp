locals {
  s3_common_tags = {
    service = "AWS/S3"
  }
}

category "s3_access_point" {
  title = "S3 Access Point"
  color = local.storage_color
  icon  = "file-open"
}

category "s3_bucket" {
  title = "S3 Bucket"
  href  = "/aws_insights.dashboard.s3_bucket_detail?input.bucket_arn={{.properties.'ARN' | @uri}}"
  icon  = "heroicons-outline:archive-box"
  color = local.storage_color
}
