locals {
  kms_common_tags = {
    service = "AWS/KMS"
  }
}

category "kms_alias" {
  title = "KMS Alias"
  color = local.security_color
  icon  = "alternate_email"
}

category "kms_key" {
  title = "KMS Key"
  color = local.security_color
  href  = "/aws_insights.dashboard.kms_key_detail?input.key_arn={{.properties.'ARN' | @uri}}"
  icon  = "key"
}
