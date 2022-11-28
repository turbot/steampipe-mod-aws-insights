locals {
  cloudwatch_common_tags = {
    service = "AWS/CloudWatch"
  }
}

category "aws_cloudwatch_log_group" {
  title = "CloudWatch Log Group"
  color = local.management_governance_color
  icon  = "text:CW"
  href  = "/aws_insights.dashboard.aws_cloudwatch_log_group_detail?input.log_group_arn={{.properties.'ARN' | @uri}}"
}

category "aws_cloudwatch_log_metric_filter" {
  title = "CloudWatch Log Metric Filter"
  color = local.management_governance_color
  icon  = "text:LMF"
}