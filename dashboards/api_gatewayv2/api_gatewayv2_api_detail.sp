dashboard "api_gatewayv2_api_detail" {
  title         = "AWS API Gateway V2 API Detail"
  documentation = file("./dashboards/api_gatewayv2/docs/api_gatewayv2_api_detail.md")

  tags = merge(local.api_gatewayv2_common_tags, {
    type = "Detail"
  })

  input "api_id" {
    title = "Select an API:"
    query = query.aws_api_gatewayv2_api_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_api_gatewayv2_api_protocol
      args = {
        api_id = self.input.api_id.value
      }
    }

    card {
      width = 2
      query = query.aws_api_gatewayv2_stage_count
      args = {
        api_id = self.input.api_id.value
      }
    }

    card {
      width = 2
      query = query.aws_api_gatewayv2_default_endpoint
      args = {
        api_id = self.input.api_id.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_api_gatewayv2_api_node,
        node.aws_api_gatewayv2_api_to_lambda_function_node,
        node.aws_api_gatewayv2_api_to_sqs_queue_node,
        node.aws_api_gatewayv2_api_to_sfn_state_machine_node,
        node.aws_api_gatewayv2_api_to_kinesis_stream_node,
        node.aws_api_gatewayv2_api_to_ec2_load_balancer_listener_node,
        node.aws_api_gatewayv2_api_from_api_gatewayv2_stage_node
      ]

      edges = [
        edge.aws_api_gatewayv2_api_to_lambda_function_edge,
        edge.aws_api_gatewayv2_api_to_sqs_queue_edge,
        edge.aws_api_gatewayv2_api_to_sfn_state_machine_edge,
        edge.aws_api_gatewayv2_api_to_kinesis_stream_edge,
        edge.aws_api_gatewayv2_api_to_ec2_load_balancer_listener_edge,
        edge.aws_api_gatewayv2_api_from_api_gatewayv2_stage_edge
      ]

      args = {
        api_id = self.input.api_id.value
      }
    }
  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 3
        query = query.aws_api_gatewayv2_api_overview
        args = {
          api_id = self.input.api_id.value
        }

      }

      table {
        title = "Tags"
        width = 3
        query = query.aws_api_gatewayv2_api_tags
        args = {
          api_id = self.input.api_id.value
        }
      }


      table {
        title = "Stages"
        width = 6
        query = query.aws_api_gatewayv2_api_stages
        args = {
          api_id = self.input.api_id.value
        }

      }
    }

  }

  container {


    container {

      table {
        title = "Integrations"
        query = query.aws_api_gatewayv2_api_integrations
        args = {
          api_id = self.input.api_id.value
        }

      }

    }

  }

}

query "aws_api_gatewayv2_api_input" {
  sql = <<-EOQ
    select
      title as label,
      api_id as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_api_gatewayv2_api
    order by
      title;
  EOQ
}

query "aws_api_gatewayv2_api_protocol" {
  sql = <<-EOQ
    select
      'Protocol Type' as label,
      protocol_type as value
    from
      aws_api_gatewayv2_api
    where
      api_id = $1;
  EOQ

  param "api_id" {}
}

query "aws_api_gatewayv2_stage_count" {
  sql = <<-EOQ
    select
      'Stage Count' as label,
      count(stage_name) as value
    from
      aws_api_gatewayv2_stage
    where
      api_id = $1;
  EOQ

  param "api_id" {}
}

query "aws_api_gatewayv2_default_endpoint" {
  sql = <<-EOQ
    select
      'Default Endpoint' as label,
      case when disable_execute_api_endpoint then 'Disabled' else 'Enabled' end as value,
      case when disable_execute_api_endpoint then 'ok' else 'alert' end as type
    from
      aws_api_gatewayv2_api
    where
      api_id = $1;
  EOQ

  param "api_id" {}
}

query "aws_api_gatewayv2_api_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      api_id as "API ID",
      api_endpoint as "API Endpoint",
      created_date as "Created Time",
      title as "Title",
      region as "Region",
      account_id as "Account ID"
    from
      aws_api_gatewayv2_api
    where
      api_id = $1;
  EOQ

  param "api_id" {}
}

query "aws_api_gatewayv2_api_tags" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      aws_api_gatewayv2_api
    where
      api_id = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
    EOQ

  param "api_id" {}
}

query "aws_api_gatewayv2_api_stages" {
  sql = <<-EOQ
    select
      stage_name as "Name",
      deployment_id as "Deployment ID",
      auto_deploy as "Auto Deploy",
      created_date as "Created Time",
      last_updated_date as "Updated Time"
    from
      aws_api_gatewayv2_stage
    where
      api_id = $1;
  EOQ

  param "api_id" {}
}

query "aws_api_gatewayv2_api_integrations" {
  sql = <<-EOQ
    select
      integration_id as "Integration ID",
      integration_uri as "Integration URI",
      integration_method as "Integration Method",
      integration_type as "Integration Type",
      integration_subtype as "Integration Subtype",
      request_parameters as "Request Parameters"
    from
      aws_api_gatewayv2_integration
    where
      api_id = $1;
  EOQ

  param "api_id" {}
}

node "aws_api_gatewayv2_api_node" {
  category = category.aws_api_gatewayv2_api

  sql = <<-EOQ
    select
      api_id as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'API Endpoint', api_endpoint,
        'ID', api_id,
        'Created Date', created_date,
        'Account ID', account_id,
        'Region', region,
        'Protocol Type', protocol_type
      ) as properties
    from
      aws_api_gatewayv2_api
    where
      api_id = $1;
  EOQ

  param "api_id" {}
}

node "aws_api_gatewayv2_api_to_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      f.arn as id,
      f.title as title,
      jsonb_build_object (
        'ARN', f.arn,
        'Runtime', runtime,
        'Architectures', architectures,
        'Region', f.region,
        'Account ID', f.account_id
      ) as properties
    from
      aws_api_gatewayv2_integration as i
      join aws_lambda_function as f on i.integration_uri = f.arn
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      a.api_id = $1;
  EOQ

  param "api_id" {}
}

edge "aws_api_gatewayv2_api_to_lambda_function_edge" {
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
      a.api_id = $1;
  EOQ

  param "api_id" {}
}

node "aws_api_gatewayv2_api_to_sqs_queue_node" {
  category = category.aws_sqs_queue

  sql = <<-EOQ
    select
      q.queue_arn as id,
      q.title as title,
      jsonb_build_object (
        'ARN', queue_arn,
        'Region', q.region,
        'Account ID', q.account_id
      ) as properties
    from
      aws_api_gatewayv2_integration as i
      join aws_sqs_queue as q on i.request_parameters ->> 'QueueUrl' = q.queue_url
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      integration_subtype like '%SQS-%' and a.api_id = $1;
  EOQ

  param "api_id" {}
}

edge "aws_api_gatewayv2_api_to_sqs_queue_edge" {
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
      integration_subtype like '%SQS-%' and a.api_id = $1;
  EOQ

  param "api_id" {}
}

node "aws_api_gatewayv2_api_to_sfn_state_machine_node" {
  category = category.aws_sfn_state_machine

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
      integration_subtype like '%StepFunctions-%' and a.api_id = $1;
  EOQ

  param "api_id" {}
}

edge "aws_api_gatewayv2_api_to_sfn_state_machine_edge" {
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
      integration_subtype like '%StepFunctions-%' and a.api_id = $1;
  EOQ

  param "api_id" {}
}

node "aws_api_gatewayv2_api_to_kinesis_stream_node" {
  category = category.aws_kinesis_stream

  sql = <<-EOQ
    select
      s.stream_arn as id,
      s.title as title,
      jsonb_build_object (
        'ARN', s.stream_arn,
        'Region', s.region,
        'Account ID', s.account_id,
        'Status', s.stream_status,
        'Encryption Type', s.encryption_type
      ) as properties
    from
      aws_api_gatewayv2_integration as i
      join aws_kinesis_stream as s on i.request_parameters ->> 'StreamName' = s.stream_name
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      integration_subtype like '%Kinesis-%' and a.api_id = $1;
  EOQ

  param "api_id" {}
}

edge "aws_api_gatewayv2_api_to_kinesis_stream_edge" {
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
      integration_subtype like '%Kinesis-%' and a.api_id = $1;
  EOQ

  param "api_id" {}
}

node "aws_api_gatewayv2_api_to_ec2_load_balancer_listener_node" {
  category = category.aws_ec2_load_balancer_listener

  sql = <<-EOQ
    select
      lb.arn as id,
      lb.title as title,
      jsonb_build_object (
        'ARN', lb.arn,
        'Account ID', lb.account_id,
        'Region', lb.region,
        'Protocol', lb.protocol,
        'Port', lb.port,
        'SSL Policy', coalesce(lb.ssl_policy, 'None')
      ) as properties
    from
      aws_api_gatewayv2_integration as i
      join aws_ec2_load_balancer_listener as lb on i.integration_uri = lb.arn
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      a.api_id = $1;
  EOQ

  param "api_id" {}
}

edge "aws_api_gatewayv2_api_to_ec2_load_balancer_listener_edge" {
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
      a.api_id = $1;
  EOQ

  param "api_id" {}
}

node "aws_api_gatewayv2_api_from_api_gatewayv2_stage_node" {
  category = category.aws_api_gatewayv2_stage

  sql = <<-EOQ
    select
      s.stage_name as id,
      s.title as title,
      jsonb_build_object (
        'Deployment ID', s.deployment_id,
        'Auto Deploy', s.auto_deploy,
        'Created Time', s.created_date,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      aws_api_gatewayv2_stage as s
      join aws_api_gatewayv2_api as a on a.api_id = s.api_id
    where
      a.api_id = $1;
  EOQ

  param "api_id" {}
}

edge "aws_api_gatewayv2_api_from_api_gatewayv2_stage_edge" {
  title = "deploys"

  sql = <<-EOQ
    select
      s.stage_name as from_id,
      a.api_id as to_id
    from
      aws_api_gatewayv2_stage as s
      join aws_api_gatewayv2_api as a on a.api_id = s.api_id
    where
      a.api_id = $1;
  EOQ

  param "api_id" {}
}
