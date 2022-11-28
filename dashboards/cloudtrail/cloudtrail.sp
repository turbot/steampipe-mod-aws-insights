locals {
  cloudtrail_common_tags = {
    service = "AWS/CloudTrail"
  }
}

category "aws_cloudtrail_trail" {
  title = "CloudTrail Trail"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.aws_cloudtrail_trail_detail?input.trail_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:CT"
}