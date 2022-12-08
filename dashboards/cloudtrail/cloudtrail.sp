locals {
  cloudtrail_common_tags = {
    service = "AWS/CloudTrail"
  }
}

category "cloudtrail_trail" {
  title = "CloudTrail Trail"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.cloudtrail_trail_detail?input.trail_arn={{.properties.'ARN' | @uri}}"
  icon  = "trail-length-medium"
}