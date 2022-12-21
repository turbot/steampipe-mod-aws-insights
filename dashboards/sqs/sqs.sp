locals {
  sqs_common_tags = {
    service = "AWS/SQS"
  }
}

category "sqs_queue" {
  title = "SQS Queue"
  color = local.application_integration_color
  href  = "/aws_insights.dashboard.sqs_queue_detail?input.queue_arn={{.properties.'ARN' | @uri}}"
  icon  = "format-list-bulleted-add"
}
