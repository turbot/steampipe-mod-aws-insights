locals {
  lambda_common_tags = {
    service = "AWS/Lambda"
  }
}

category "lambda_alias" {
  title = "Lambda Alias"
  color = local.compute_color
  icon  = "alternate_email"
}

category "lambda_function" {
  title = "Lambda Function"
  color = local.compute_color
  href  = "/aws_insights.dashboard.lambda_function_detail?input.lambda_arn={{.properties.'ARN' | @uri}}"
  icon  = "function"
}

category "lambda_version" {
  title = "Lambda Version"
  color = local.compute_color
  icon  = "difference"
}
