locals {
  eventbridge_common_tags = {
    service = "AWS/EventBridge"
  }
}

category "aws_eventbridge_bus" {
  title = "EventBridge Bus"
  color = local.application_integration_color
  icon  = "text:EventBus"
}

category "aws_eventbridge_rule" {
  title = "EventBridge Rule"
  color = local.application_integration_color
  href  = "/aws_insights.dashboard.aws_eventbridge_rule_detail?input.eventbridge_rule_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Rule"
}