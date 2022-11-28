locals {
  sqs_common_tags = {
    service = "AWS/SQS"
  }
}

category "aws_sqs_queue" {
  title = "SQS Queue"
  color = local.application_integration_color
  href  = "/aws_insights.dashboard.aws_sqs_queue_detail?input.queue_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Queue"
}
