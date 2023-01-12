locals {
  api_gatewayv2_common_tags = {
    service = "AWS/API Gateway V2"
  }
}

category "api_gatewayv2_api" {
  title = "API Gateway V2 API"
  color = local.front_end_web_color
  href  = "/aws_insights.dashboard.api_gatewayv2_api_detail?input.api_id={{.properties.'ID' | @uri}}"
  icon  = "api"
}

category "api_gatewayv2_integration" {
  title = "API Gateway V2 Integration"
  color = local.front_end_web_color
  icon  = "extension"
}

category "api_gatewayv2_stage" {
  title = "API Gateway V2 Stage"
  color = local.front_end_web_color
  icon  = "schema"
}
