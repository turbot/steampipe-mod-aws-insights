dashboard "api_gatewayv2_api_detail" {
  title         = "AWS API Gateway V2 API Detail"
  documentation = file("./dashboards/api_gatewayv2/docs/api_gatewayv2_api_detail.md")

  tags = merge(local.api_gatewayv2_common_tags, {
    type = "Detail"
  })

  input "api_id" {
    title = "Select an API:"
    query = query.api_gatewayv2_api_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.api_gatewayv2_api_protocol
      args  = [self.input.api_id.value]
    }

    card {
      width = 2
      query = query.api_gatewayv2_stage_count
      args  = [self.input.api_id.value]
    }

    card {
      width = 2
      query = query.api_gatewayv2_default_endpoint
      args  = [self.input.api_id.value]
    }

  }

  with "ec2_load_balancer_listeners" {
    query = query.api_gatewayv2_api_ec2_load_balancer_listeners
    args  = [self.input.api_id.value]
  }

  with "kinesis_streams" {
    query = query.api_gatewayv2_api_kinesis_streams
    args  = [self.input.api_id.value]
  }

  with "lambda_functions" {
    query = query.api_gatewayv2_api_lambda_functions
    args  = [self.input.api_id.value]
  }

  with "sqs_queues" {
    query = query.api_gatewayv2_api_sqs_queues
    args  = [self.input.api_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.api_gatewayv2_api
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }

      node {
        base = node.api_gatewayv2_stage
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }

      node {
        base = node.ec2_load_balancer_listener
        args = {
          ec2_load_balancer_listener_arns = with.ec2_load_balancer_listeners.rows[*].listener_arn
        }
      }

      node {
        base = node.kinesis_stream
        args = {
          kinesis_stream_arns = with.kinesis_streams.rows[*].kinesis_stream_arn
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions.rows[*].function_arn
        }
      }

      node {
        base = node.sfn_state_machine
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }

      node {
        base = node.sqs_queue
        args = {
          sqs_queue_arns = with.sqs_queues.rows[*].queue_arn
        }
      }

      edge {
        base = edge.api_gatewayv2_api_to_ec2_load_balancer_listener
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }


      edge {
        base = edge.api_gatewayv2_api_to_kinesis_stream
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }

      edge {
        base = edge.api_gatewayv2_api_to_lambda_function
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }

      edge {
        base = edge.api_gatewayv2_api_to_sfn_state_machine
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }

      edge {
        base = edge.api_gatewayv2_api_to_sqs_queue
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }

      edge {
        base = edge.api_gatewayv2_stage_to_api_gatewayv2_api
        args = {
          api_gatewayv2_api_ids = [self.input.api_id.value]
        }
      }

    }
  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 3
        query = query.api_gatewayv2_api_overview
        args  = [self.input.api_id.value]

      }

      table {
        title = "Tags"
        width = 3
        query = query.api_gatewayv2_api_tags
        args  = [self.input.api_id.value]
      }


      table {
        title = "Stages"
        width = 6
        query = query.api_gatewayv2_api_stages
        args  = [self.input.api_id.value]
      }
    }

  }

  container {


    container {

      table {
        title = "Integrations"
        query = query.api_gatewayv2_api_integrations
        args  = [self.input.api_id.value]
      }
      
    }

  }
}

# Input queries

query "api_gatewayv2_api_input" {
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

# With queries

query "api_gatewayv2_api_ec2_load_balancer_listeners" {
  sql = <<-EOQ
    select
      lb.arn as listener_arn
    from
      aws_api_gatewayv2_integration as i
      join aws_ec2_load_balancer_listener as lb on i.integration_uri = lb.arn
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      a.api_id = $1;
  EOQ
}

query "api_gatewayv2_api_kinesis_streams" {
  sql = <<-EOQ
    select
      s.stream_arn as kinesis_stream_arn
    from
      aws_api_gatewayv2_integration as i
      join aws_kinesis_stream as s on i.request_parameters ->> 'StreamName' = s.stream_name
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      integration_subtype like '%Kinesis-%' and a.api_id = $1;
  EOQ
}

query "api_gatewayv2_api_lambda_functions" {
  sql = <<-EOQ
    select
      f.arn as function_arn
    from
      aws_api_gatewayv2_integration as i
      join aws_lambda_function as f on i.integration_uri = f.arn
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      a.api_id = $1;
  EOQ
}

query "api_gatewayv2_api_sqs_queues" {
  sql = <<-EOQ
    select
      q.queue_arn as queue_arn
    from
      aws_api_gatewayv2_integration as i
      join aws_sqs_queue as q on i.request_parameters ->> 'QueueUrl' = q.queue_url
      join aws_api_gatewayv2_api as a on a.api_id = i.api_id
    where
      integration_subtype like '%SQS-%' and a.api_id = $1;
  EOQ
}

# Card queries

query "api_gatewayv2_api_protocol" {
  sql = <<-EOQ
    select
      'Protocol Type' as label,
      protocol_type as value
    from
      aws_api_gatewayv2_api
    where
      api_id = $1;
  EOQ
}

query "api_gatewayv2_stage_count" {
  sql = <<-EOQ
    select
      'Stage Count' as label,
      count(stage_name) as value
    from
      aws_api_gatewayv2_stage
    where
      api_id = $1;
  EOQ
}

query "api_gatewayv2_default_endpoint" {
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
}

# Other detail page queries

query "api_gatewayv2_api_overview" {
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
}

query "api_gatewayv2_api_tags" {
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
}

query "api_gatewayv2_api_stages" {
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
}

query "api_gatewayv2_api_integrations" {
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
}
