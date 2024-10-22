locals {
  sns_common_tags = {
    service = "AWS/SNS"
  }
}

category "sns_topic" {
  title = "SNS Topic"
  color = local.application_integration_color
  href  = "/aws_insights.dashboard.sns_topic_detail?input.topic_arn={{.properties.'ARN' | @uri}}"
  icon  = "podcasts"
}

category "sns_topic_subscription" {
  title = "SNS Subscription"
  color = local.application_integration_color
  icon  = "broadcast_on_personal"
}
