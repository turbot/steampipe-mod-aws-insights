locals {
  cloudfront_common_tags = {
    service = "AWS/CloudFront"
  }
}

category "aws_cloudfront_distribution" {
  title = "CloudFront Distribution"
  color = local.content_delivery_color
  href  = "/aws_insights.dashboard.aws_cloudfront_distribution_detail?input.distribution_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:CD"
}
