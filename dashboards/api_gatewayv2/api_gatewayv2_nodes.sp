node "api_gatewayv2_api" {
  category = category.api_gatewayv2_api

  sql = <<-EOQ
    select
      api_id as id,
      left(title, 30) as title,
      jsonb_build_object(
        'Name', name,
        'ID', api_id,
        'Endpoint', api_endpoint,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_api_gatewayv2_api
    where
      api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}

node "api_gatewayv2_stage" {
  category = category.api_gatewayv2_stage

  sql = <<-EOQ
    select
      stage_name as id,
      title as title,
      jsonb_build_object (
        'Deployment ID', deployment_id,
        'Auto Deploy', auto_deploy,
        'Created Time', created_date,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_api_gatewayv2_stage
    where
      api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}