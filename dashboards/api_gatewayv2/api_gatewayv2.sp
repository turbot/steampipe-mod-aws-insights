locals {
  api_gatewayv2_common_tags = {
    service = "AWS/API Gateway V2"
  }
}

category "api_gatewayv2_api" {
  title = "API Gatewayv2 API"
  href  = "/aws_insights.dashboard.api_gatewayv2_api_detail?input.api_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:bolt"
  color = local.front_end_web_color
}

category "api_gatewayv2_integration" {
  title = "API Gatewayv2 Integration"
  icon  = "heroicons-outline:puzzle-piece"
  color = local.front_end_web_color
}

category "api_gatewayv2_stage" {
  title = "API Gatewayv2 Stage"
  color = local.front_end_web_color
  icon  = "text:Stage"
}
