locals {
  api_gatewayv2_common_tags = {
    service = "AWS/API Gateway V2"
  }
}

category "api_gatewayv2_api" {
  title = "API Gateway V2 API"
  href  = "/aws_insights.dashboard.api_gatewayv2_api_detail?input.api_id={{.properties.'ID' | @uri}}"
  icon  = "api"
  color = local.front_end_web_color
}

category "api_gatewayv2_integration" {
  title = "API Gateway V2 Integration"
  icon  = "extension"
  color = local.front_end_web_color
}

category "api_gatewayv2_stage" {
  title = "API Gateway V2 Stage"
  color = local.front_end_web_color
  icon  = "schema"
}
