locals {
  sns_common_tags = {
    service = "AWS/SNS"
  }
}

category "sns_topic" {
  title = "SNS Topic"
  href  = "/aws_insights.dashboard.sns_topic_detail?input.topic_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Topic"
  color = local.application_integration_color
}

category "sns_topic_subscription" {
  title = "SNS Subscription"
  icon  = "heroicons-outline:rss"
  color = local.application_integration_color
}
