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
      base  = graph.aws_graph_categories
      query = query.aws_api_gatewayv2_api_relationships_graph
      args = {
        api_id = self.input.api_id.value
      }

      category "aws_appconfig_application" {
        color = "pink"
      }

      category "aws_api_gatewayv2_stage" {
        icon = local.aws_api_gatewayv2_api_icon
      }

      category "aws_api_gatewayv2_api" {
        icon = local.aws_api_gatewayv2_api_icon
      }

      category "aws_sqs_queue" {
        icon = local.aws_sqs_queue_icon
      }

      category "aws_sfn_state_machine" {
        color = "pink"
      }

      category "uses" {
        color = "green"
      }
    }
  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_api_gatewayv2_api_overview
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

query "aws_api_gatewayv2_api_relationships_graph" {
  sql = <<-EOQ
    with api as (
      select * from aws_api_gatewayv2_api where api_id = $1
    )

    select
      null as from_id,
      null as to_id,
      api_id as id,
      title,
      'aws_api_gatewayv2_api' as category,
      jsonb_build_object( 'Name', name, 'API Endpoint', api_endpoint, 'Created Date', created_date, 'Account ID', account_id, 'Region', region, 'Protocol Type', protocol_type) as properties 
    from
      api

    -- To Lambda function (node)
    union all
    select
      null as from_id,
      null as to_id,
      f.arn as id,
      f.title as title,
      'aws_lambda_function' as category,
      jsonb_build_object( 'Runtime', runtime, 'Architectures', architectures, 'Region', f.region, 'Account ID', f.account_id ) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_lambda_function f
        on i.integration_uri = f.arn 
      join
        api a 
        on a.api_id = i.api_id

    -- To Lambda function (edge)
    union all
    select
      a.api_id as from_id,
      f.arn as to_id,
      null as id,
      'Integrated with' as title,
      'uses' as category,
      jsonb_build_object( 'Name', a.name, 'API Endpoint', a.api_endpoint, 'Protocol Type', protocol_type) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_lambda_function f 
        on i.integration_uri = f.arn 
      join
        api a 
        on a.api_id = i.api_id

    -- To SQS queue (node)
    union all
    select
      null as from_id,
      null as to_id,
      q.queue_arn as id,
      q.title as title,
      'aws_sqs_queue' as category,
      jsonb_build_object( 'ARN', queue_arn, 'Region', q.region, 'Account ID', q.account_id ) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_sqs_queue q
        on i.request_parameters ->> 'QueueUrl' = q.queue_url 
      join
        api a
        on a.api_id = i.api_id
    where
      integration_subtype like '%SQS-%'


    -- To SQS queue (edge)
    union all
    select
      a.api_id as from_id,
      q.queue_arn as to_id,
      null as id,
      'Integrated with' as title,
      'uses' as category,
      jsonb_build_object( 'Name', a.name, 'API Endpoint', a.api_endpoint, 'Protocol Type', protocol_type) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_sqs_queue q
        on i.request_parameters ->> 'QueueUrl' = q.queue_url 
      join
        api a
        on a.api_id = i.api_id
    where
      integration_subtype like '%SQS-%'

    -- To step function state machine (node)
    union all
    select
      null as from_id,
      null as to_id,
      sm.arn as id,
      sm.title as title,
      'aws_sfn_state_machine' as category,
      jsonb_build_object( 'ARN', sm.arn, 'Region', sm.region, 'Account ID', sm.account_id, 'Status', sm.status, 'Type', sm.type ) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_sfn_state_machine sm
        on i.request_parameters ->> 'StateMachineArn' = sm.arn 
      join
        api a
        on a.api_id = i.api_id
    where
      integration_subtype like '%StepFunctions-%'


    -- To step function state machine (edge)
    union all
    select
      a.api_id as from_id,
      sm.arn as to_id,
      null as id,
      'Integrated with' as title,
      'uses' as category,
      jsonb_build_object( 'Name', a.name, 'API Endpoint', a.api_endpoint, 'Protocol Type', protocol_type) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_sfn_state_machine sm
        on i.request_parameters ->> 'StateMachineArn' = sm.arn 
      join
        api a
        on a.api_id = i.api_id
    where
      integration_subtype like '%StepFunctions-%'

    -- To kinesis stream (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.stream_arn as id,
      s.title as title,
      'aws_kinesis_stream' as category,
      jsonb_build_object( 'ARN', s.stream_arn, 'Region', s.region, 'Account ID', s.account_id, 'Status', s.stream_status, 'Encryption Type', s.encryption_type ) as properties
    from
      aws_api_gatewayv2_integration i 
      join
        aws_kinesis_stream s
        on i.request_parameters ->> 'StreamName' = s.stream_name 
      join
        api a
        on a.api_id = i.api_id
    where
      integration_subtype like '%Kinesis-%'

    -- To kinesis stream (edge)
    union all
    select
      a.api_id as from_id,
      s.stream_arn as to_id,
      null as id,
      'Integrated with' as title,
      'uses' as category,
      jsonb_build_object( 'Name', a.name, 'API Endpoint', a.api_endpoint, 'Protocol Type', protocol_type) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_kinesis_stream s
        on i.request_parameters ->> 'StreamName' = s.stream_name 
      join
        api a
        on a.api_id = i.api_id
    where
      integration_subtype like '%Kinesis-%'

    -- To load balancer (node)
    union all
    select
      null as from_id,
      null as to_id,
      lb.arn as id,
      lb.title as title,
      'aws_ec2_classic_load_balancer' as category,
      jsonb_build_object( 'ARN', lb.arn, 'Account ID', lb.account_id, 'Region', lb.region, 'Protocol', lb.protocol, 'Port', lb.port, 'SSL Policy', coalesce(lb.ssl_policy, 'None') ) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_ec2_load_balancer_listener lb
        on i.integration_uri = lb.arn 
      join
        api a 
        on a.api_id = i.api_id

    -- To load balancer (edge)
    union all
    select
      a.api_id as from_id,
      lb.arn as to_id,
      null as id,
      'Integrated with' as title,
      'uses' as category,
      jsonb_build_object( 'Name', a.name, 'API Endpoint', a.api_endpoint, 'Protocol Type', protocol_type) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_ec2_load_balancer_listener lb
        on i.integration_uri = lb.arn 
      join
        api a 
        on a.api_id = i.api_id

    -- To appconfig application (node)
    union all
    select
      null as from_id,
      null as to_id,
      ap.arn as id,
      ap.title as title,
      'aws_appconfig_application' as category,
      jsonb_build_object( 'ARN', ap.arn, 'Region', ap.region, 'Account ID', ap.account_id, 'Description', ap.description ) as properties
    from
      aws_api_gatewayv2_integration i 
      join
        aws_appconfig_application ap
        on i.request_parameters ->> 'Application' = ap.name 
      join
        api a
        on a.api_id = i.api_id
    where
      integration_subtype like '%AppConfig-%'

    -- To appconfig application (edge)
    union all
    select
      a.api_id as from_id,
      ap.arn as to_id,
      null as id,
      'Integrated with' as title,
      'uses' as category,
      jsonb_build_object( 'Name', a.name, 'API Endpoint', a.api_endpoint, 'Protocol Type', protocol_type) as properties 
    from
      aws_api_gatewayv2_integration i 
      join
        aws_appconfig_application ap
        on i.request_parameters ->> 'Application' = ap.name 
      join
        api a
        on a.api_id = i.api_id
    where
      integration_subtype like '%AppConfig-%'

    -- From API gateway v2 stage (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.stage_name as id,
      s.title as title,
      'aws_api_gatewayv2_stage' as category,
      jsonb_build_object( 'Deployment ID', s.deployment_id, 'Auto Deploy', s.auto_deploy, 'Created Time', s.created_date, 'Region', s.region, 'Account ID', s.account_id ) as properties 
    from
      aws_api_gatewayv2_stage s 
      join
        api a 
        on a.api_id = s.api_id  

    -- From API gateway v2 stage (edge)
    union all
    select
      s.stage_name as from_id,
      a.api_id as to_id,
      null as id,
      'Deploys' as title,
      'uses' as category,
      jsonb_build_object( 'Deployment ID', s.deployment_id, 'Auto Deploy', s.auto_deploy, 'Created Time', s.created_date, 'Region', s.region, 'Account ID', s.account_id ) as properties 
    from
      aws_api_gatewayv2_stage s 
      join
        api a 
        on a.api_id = s.api_id

    order by
      category,
      from_id,
      to_id;
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
      protocol_type as "Protocol Type",
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
      arn as "ARN",
      integration_id as "Integration ID",
      integration_method as "Integration Method",
      integration_type as "Integration Type",
      integration_uri as "Integration URI",
      integration_subtype as "Integration Subtype",
      request_parameters as "Request Parameters"
    from
      aws_api_gatewayv2_integration
    where
      api_id = $1;
  EOQ

  param "api_id" {}
}
