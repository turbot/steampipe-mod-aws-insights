locals {
  sns_common_tags = {
    service = "AWS/SNS"
  }
}

category "aws_sns_topic" {
  title = "SNS Topic"
  href  = "/aws_insights.dashboard.aws_sns_topic_detail?input.topic_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Topic"
  color = local.application_integration_color
}

category "aws_sns_topic_subscription" {
  title = "SNS Subscription"
  icon  = "rss"
  color = local.application_integration_color
}
