locals {
  acm_common_tags = {
    service = "AWS/ACM"
  }
}

category "acm_certificate" {
  title = "ACM Certificate"
  color = local.security_color
  href  = "/aws_insights.dashboard.acm_certificate_detail?input.certificate_arn={{.properties.'ARN' | @uri}}"
  icon  = "verified_user"
}

