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
      width = 3
      query = query.api_gatewayv2_api_protocol
      args  = [self.input.api_id.value]
    }

    card {
      width = 3
      query = query.api_gatewayv2_stage_count
      args  = [self.input.api_id.value]
    }

    card {
      width = 3
      query = query.api_gatewayv2_default_endpoint
      args  = [self.input.api_id.value]
    }

  }

  with "ec2_load_balancer_listeners_for_api_gatewayv2_api" {
    query = query.ec2_load_balancer_listeners_for_api_gatewayv2_api
    args  = [self.input.api_id.value]
  }

  with "kinesis_streams_for_api_gatewayv2_api" {
    query = query.kinesis_streams_for_api_gatewayv2_api
    args  = [self.input.api_id.value]
  }

  with "lambda_functions_for_api_gatewayv2_api" {
    query = query.lambda_functions_for_api_gatewayv2_api
    args  = [self.input.api_id.value]
  }

  with "source_sqs_queues_for_api_gatewayv2_api" {
    query = query.source_sqs_queues_for_api_gatewayv2_api
    args  = [self.input.api_id.value]
  }

  with "target_sqs_queues_for_api_gatewayv2_api" {
    query = query.target_sqs_queues_for_api_gatewayv2_api
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
          ec2_load_balancer_listener_arns = with.ec2_load_balancer_listeners_for_api_gatewayv2_api.rows[*].listener_arn
        }
      }

      node {
        base = node.kinesis_stream
        args = {
          kinesis_stream_arns = with.kinesis_streams_for_api_gatewayv2_api.rows[*].kinesis_stream_arn
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions_for_api_gatewayv2_api.rows[*].function_arn
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
          sqs_queue_arns = with.source_sqs_queues_for_api_gatewayv2_api.rows[*].queue_arn
        }
      }

      node {
        base = node.sqs_queue
        args = {
          sqs_queue_arns = with.target_sqs_queues_for_api_gatewayv2_api.rows[*].queue_arn
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
        base = edge.sqs_queue_to_api_gatewayv2_api
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

  container {

    table {
      title = "Integrations"
      query = query.api_gatewayv2_api_integrations
      args  = [self.input.api_id.value]
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

query "ec2_load_balancer_listeners_for_api_gatewayv2_api" {
  sql = <<-EOQ
  with filtered_api as (
    select
      api_id,
      account_id,
      region
    from
      aws_api_gatewayv2_api
    where
      api_id = $1
    order by
      api_id
  ),
  filtered_integration as (
    select
      integration_uri,
      account_id,
      region,
      api_id
    from
      aws_api_gatewayv2_integration as i
    where
      api_id = $1
      and account_id = (select account_id from filtered_api)
      and region = (select region from filtered_api)
    order by
      integration_uri
  ),
  filtered_load_balancer_listener as (
    select
      arn,
      account_id,
      region
    from
      aws_ec2_load_balancer_listener
    where
    arn = (select integration_uri from filtered_integration)
    and account_id = (select account_id from filtered_integration)
    and region = (select region from filtered_integration)
    order by
      arn
  )
  select
    lb.arn as listener_arn
  from
    filtered_integration i
    join filtered_load_balancer_listener lb on i.integration_uri = lb.arn
    join filtered_api a on a.api_id = i.api_id;
  EOQ
}

query "kinesis_streams_for_api_gatewayv2_api" {
  sql = <<-EOQ
    with filtered_api as (
      select
          api_id,
          account_id,
          region
      from
          aws_api_gatewayv2_api
      where
          api_id = $1
    ),
    filtered_integration as (
      select
        request_parameters,
        account_id,
        region,
        api_id
      from
        aws_api_gatewayv2_integration
      where
        integration_subtype like '%Kinesis-%'
        and api_id = $1
        and account_id = (select account_id from filtered_api)
        and region = (select region from filtered_api)
    ),
    filtered_kinesis_stream as (
      select
        stream_arn,
        stream_name
      from
        aws_kinesis_stream
      where
        stream_name = (select request_parameters ->> 'StreamName' from filtered_integration)
        and account_id = (select account_id from filtered_integration)
        and region = (select region from filtered_integration)
    )
    select
      s.stream_arn as kinesis_stream_arn
    from
      filtered_integration i
      join filtered_kinesis_stream s on i.request_parameters ->> 'StreamName' = s.stream_name
      join filtered_api a on a.api_id = i.api_id;
  EOQ
}

query "lambda_functions_for_api_gatewayv2_api" {
  sql = <<-EOQ
    with filtered_api as (
      select
        api_id,
        account_id,
        region
      from
        aws_api_gatewayv2_api
      where
        api_id = $1
    ),
    filtered_integration as (
      select
        integration_uri,
        api_id,
        account_id,
        region
      from
        aws_api_gatewayv2_integration
      where
        api_id = $1
        and account_id = (select account_id from filtered_api)
        and region = (select region from filtered_api)
    ),
    filtered_lambda_function as (
      select
        arn
      from
        aws_lambda_function
      where
        arn in (select integration_uri from filtered_integration)
        and account_id = (select account_id from filtered_integration)
        and region = (select region from filtered_integration)
    )
    select
      f.arn as function_arn
    from
      filtered_integration i
      join filtered_lambda_function f on i.integration_uri = f.arn
      join filtered_api a on a.api_id = i.api_id;
  EOQ
}

query "source_sqs_queues_for_api_gatewayv2_api" {
  sql = <<-EOQ
    with filtered_api as (
      select
        api_id,
        account_id,
        region
      from
        aws_api_gatewayv2_api
      where
        api_id = $1
    ),
    filtered_integration as (
      select
        request_parameters,
        account_id,
        region,
        api_id
      from
        aws_api_gatewayv2_integration
      where
        integration_subtype like '%SQS-ReceiveMessage%'
        and account_id = (select account_id from filtered_api)
        and region = (select region from filtered_api)
        and api_id = $1
    ),
    filtered_sqs_queue as (
      select
        queue_arn,
        queue_url
      from
        aws_sqs_queue
      where
        queue_url in (select request_parameters ->> 'QueueUrl' from filtered_integration)
        and account_id = (select account_id from filtered_integration)
        and region = (select region from filtered_integration)
    )
    select
      q.queue_arn as queue_arn
    from
      filtered_integration i
      join filtered_sqs_queue q on i.request_parameters ->> 'QueueUrl' = q.queue_url
      join filtered_api a on a.api_id = i.api_id;
  EOQ
}

query "target_sqs_queues_for_api_gatewayv2_api" {
  sql = <<-EOQ
    with filtered_api as (
      select
        api_id,
        account_id,
        region
      from
        aws_api_gatewayv2_api
      where
        api_id = $1
    ),
    filtered_integration as (
      select
        request_parameters,
        api_id
      from
        aws_api_gatewayv2_integration
      where
        api_id = $1
        and integration_subtype like '%SQS-SendMessage%'
        and account_id = (select account_id from filtered_api)
        and region = (select region from filtered_api)
    ),
    filtered_sqs_queue as (
      select
        queue_arn,
        queue_url
      from
        aws_sqs_queue
      where
        queue_url in (select request_parameters ->> 'QueueUrl' from filtered_integration)
        and account_id = (select account_id from filtered_integration)
        and region = (select region from filtered_integration)
    )
    select
      q.queue_arn as queue_arn
    from
      filtered_integration i
      join filtered_sqs_queue q on i.request_parameters ->> 'QueueUrl' = q.queue_url
      join filtered_api a on a.api_id = i.api_id;
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
