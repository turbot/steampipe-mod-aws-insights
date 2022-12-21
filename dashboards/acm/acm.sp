locals {
  acm_common_tags = {
    service = "AWS/ACM"
  }
}

category "acm_certificate" {
  title = "ACM Certificate"
  href  = "/aws_insights.dashboard.acm_certificate_detail?input.certificate_arn={{.properties.'ARN' | @uri}}"
  icon  = "verified-user"
  color = local.security_color
}

