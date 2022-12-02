locals {
  lambda_common_tags = {
    service = "AWS/Lambda"
  }
}

category "lambda_alias" {
  title = "Lambda Alias"
  icon  = "at-symbol"
  color = local.compute_color
}

category "lambda_function" {
  title = "Lambda Function"
  href  = "/aws_insights.dashboard.lambda_function_detail?input.lambda_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Lambda"
  color = local.compute_color
}

category "lambda_version" {
  title = "Lambda Version"
  icon  = "document-duplicate"
  color = local.compute_color
}
