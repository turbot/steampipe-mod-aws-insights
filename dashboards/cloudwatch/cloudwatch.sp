locals {
  cloudwatch_common_tags = {
    service = "AWS/CloudWatch"
  }
}

category "cloudwatch_log_group" {
  title = "CloudWatch Log Group"
  color = local.management_governance_color
  icon  = "library_books"
  href  = "/aws_insights.dashboard.cloudwatch_log_group_detail?input.log_group_arn={{.properties.'ARN' | @uri}}"
}

category "cloudwatch_log_metric_filter" {
  title = "CloudWatch Log Metric Filter"
  color = local.management_governance_color
  icon  = "query_stats"
}