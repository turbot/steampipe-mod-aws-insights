locals {
  kms_common_tags = {
    service = "AWS/KMS"
  }
}

category "aws_kms_alias" {
  title = "KMS Key Alias"
  icon  = "key"
  color = local.security_color
}

category "aws_kms_key" {
  title = "KMS Key"
  href  = "/aws_insights.dashboard.aws_kms_key_detail?input.key_arn={{.properties.'ARN' | @uri}}"
  icon  = "key"
  color = local.security_color
}
