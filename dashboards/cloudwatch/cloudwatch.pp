locals {
  cloudwatch_common_tags = {
    service = "AWS/CloudWatch"
  }
}

category "cloudwatch_log_group" {
  title = "CloudWatch Log Group"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.cloudwatch_log_group_detail?input.log_group_arn={{.properties.'ARN' | @uri}}"
  icon  = "library_books"
}

category "cloudwatch_log_metric_filter" {
  title = "CloudWatch Log Metric Filter"
  color = local.management_governance_color
  icon  = "data_exploration"
}