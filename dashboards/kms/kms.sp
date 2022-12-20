locals {
  kms_common_tags = {
    service = "AWS/KMS"
  }
}

category "kms_alias" {
  title = "KMS Alias"
  icon  = "heroicons-outline:key"
  color = local.security_color
}

category "kms_key" {
  title = "KMS Key"
  href  = "/aws_insights.dashboard.kms_key_detail?input.key_arn={{.properties.'ARN' | @uri}}"
  icon  = "heroicons-outline:key"
  color = local.security_color
}
