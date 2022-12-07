node "sfn_state_machine" {
  category = category.sfn_state_machine

  sql = <<-EOQ
    select
      sm.arn as id,
      sm.title as title,
      jsonb_build_object (
        'ARN', sm.arn,
        'Region', sm.region,
        'Account ID', sm.account_id,
        'Status', sm.status,
        'Type', sm.type
      ) as properties
    from
      aws_api_gatewayv2_integration as i
      join aws_sfn_state_machine as sm on i.request_parameters ->> 'StateMachineArn' = sm.arn
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      integration_subtype like '%StepFunctions-%' and a.api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}