locals {
  eventbridge_common_tags = {
    service = "AWS/EventBridge"
  }
}

category "eventbridge_bus" {
  title = "EventBridge Bus"
  color = local.application_integration_color
  icon  = "text:Bus"
}

category "eventbridge_rule" {
  title = "EventBridge Rule"
  color = local.application_integration_color
  href  = "/aws_insights.dashboard.eventbridge_rule_detail?input.eventbridge_rule_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Rule"
}
