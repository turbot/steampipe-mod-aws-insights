
edge "api_gateway_api_to_api_gateway_integration" {
  title = "integration"

  sql = <<-EOQ
    select
      api_id as from_id,
      integration_id as to_id
    from
      aws_api_gatewayv2_integration
    where
      api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}

edge "api_gateway_integration_to_lambda_function" {
  title = "invokes"

  sql = <<-EOQ
    select
      i.integration_id as from_id,
      i.integration_uri as to_id
    from
      aws_api_gatewayv2_integration as i
    where
      i.integration_uri = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "api_gatewayv2_api_to_ec2_load_balancer_listener" {
  title = "lb listener"

  sql = <<-EOQ
    select
      a.api_id as from_id,
      lb.arn as to_id
    from
      aws_api_gatewayv2_integration as i
      join aws_ec2_load_balancer_listener as lb on i.integration_uri = lb.arn
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      a.api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}

edge "api_gatewayv2_api_to_kinesis_stream" {
  title = "kinesis stream"

  sql = <<-EOQ
    select
      a.api_id as from_id,
      s.stream_arn as to_id
    from
      aws_api_gatewayv2_integration as i
      join aws_kinesis_stream as s on i.request_parameters ->> 'StreamName' = s.stream_name
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      integration_subtype like '%Kinesis-%' and a.api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}

edge "api_gatewayv2_api_to_lambda_function" {
  title = "lambda function"

  sql = <<-EOQ
    select
      a.api_id as from_id,
      f.arn as to_id
    from
      aws_api_gatewayv2_integration as i
      join aws_lambda_function as f on i.integration_uri = f.arn
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      a.api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}

edge "api_gatewayv2_api_to_sfn_state_machine" {
  title = "sfn state machine"

  sql = <<-EOQ
    select
      a.api_id as from_id,
      sm.arn as to_id
    from
      aws_api_gatewayv2_integration as i
      join aws_sfn_state_machine as sm on i.request_parameters ->> 'StateMachineArn' = sm.arn
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      integration_subtype like '%StepFunctions-%' and a.api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}

edge "api_gatewayv2_api_to_sqs_queue" {
  title = "sqs queue"

  sql = <<-EOQ
    select
      a.api_id as from_id,
      q.queue_arn as to_id
    from
      aws_api_gatewayv2_integration as i
      join aws_sqs_queue as q on i.request_parameters ->> 'QueueUrl' = q.queue_url
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      integration_subtype like '%SQS-%' and a.api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}

edge "api_gatewayv2_stage_to_api_gatewayv2_api" {
  title = "deploys"

  sql = <<-EOQ
    select
      stage_name as from_id,
      api_id as to_id
    from
      aws_api_gatewayv2_stage
    where
      api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}
