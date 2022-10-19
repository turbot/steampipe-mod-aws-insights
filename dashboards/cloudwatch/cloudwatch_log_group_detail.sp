dashboard "aws_cloudwatch_log_group_detail" {

  title         = "AWS CloudWatch Log Group Detail"
  documentation = file("./dashboards/cloudwatch/docs/cloudwatch_log_group_detail.md")

  tags = merge(local.cloudwatch_common_tags, {
    type = "Detail"
  })

  input "log_group_arn" {
    title = "Select a log group:"
    sql   = query.aws_cloudwatch_log_group_input.sql
    width = 4
  }

  container {

    card {
      query = query.aws_cloudwatch_log_group_retention_in_days
      width = 2
      args = {
        log_group_arn = self.input.log_group_arn.value
      }
    }

    card {
      query = query.aws_cloudwatch_log_group_stored_bytes
      width = 2
      args = {
        log_group_arn = self.input.log_group_arn.value
      }
    }

    card {
      query = query.aws_cloudwatch_log_group_metric_filter_count
      width = 2
      args = {
        log_group_arn = self.input.log_group_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_cloudwatch_log_group_unencrypted
      args = {
        log_group_arn = self.input.log_group_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_cloudwatch_log_group_node,
        node.aws_cloudwatch_log_group_to_kms_key_node,
        node.aws_cloudwatch_log_group_from_cloudtrail_trail_node,
        node.aws_cloudwatch_log_group_from_lambda_function_node,
        node.aws_cloudwatch_log_group_from_vpc_flow_logs_node,
        node.aws_cloudwatch_log_group_from_kinesis_stream_node,
        node.aws_cloudwatch_log_group_subscription_filter_from_lambda_function_node
      ]

      edges = [
        edge.aws_cloudwatch_log_group_to_kms_key_edge,
        edge.aws_cloudwatch_log_group_from_cloudtrail_trail_edge,
        edge.aws_cloudwatch_log_group_from_lambda_function_edge,
        edge.aws_cloudwatch_log_group_from_vpc_flow_logs_edge,
        edge.aws_cloudwatch_log_group_from_kinesis_stream_edge,
        edge.aws_cloudwatch_log_group_subscription_filter_from_lambda_function_edge
      ]

      args  = {
        log_group_arn = self.input.log_group_arn.value
      }

    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_cloudwatch_log_group_overview
        args = {
          log_group_arn = self.input.log_group_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_cloudwatch_log_group_tags
        args = {
          log_group_arn = self.input.log_group_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Encryption Details"
        query = query.aws_cloudwatch_log_group_encryption_details
        args = {
          log_group_arn = self.input.log_group_arn.value
        }

        column "KMS Key ID" {
          href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.'KMS Key ID' | @uri}}"
        }
      }

    }

  }

}

query "aws_cloudwatch_log_group_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'arn', arn
      ) as tags
    from
      aws_cloudwatch_log_group
    order by
      title;
  EOQ
}

query "aws_cloudwatch_log_group_retention_in_days" {
  sql = <<-EOQ
    select
      retention_in_days as value,
      'Retention in Days' as label
    from
      aws_cloudwatch_log_group
    where
      arn = $1;
  EOQ

  param "log_group_arn" {}
}

query "aws_cloudwatch_log_group_stored_bytes" {
  sql = <<-EOQ
    select
      stored_bytes as value,
      'Stored Bytes' as label
    from
      aws_cloudwatch_log_group
    where
      arn = $1;
  EOQ

  param "log_group_arn" {}
}

query "aws_cloudwatch_log_group_metric_filter_count" {
  sql = <<-EOQ
    select
      metric_filter_count as value,
      'Metric Filter Count' as label
    from
      aws_cloudwatch_log_group
    where
      arn = $1;
  EOQ

  param "log_group_arn" {}
}

query "aws_cloudwatch_log_group_unencrypted" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_key_id is not null then 'Enabled' else 'Disabled' end as value,
      case when kms_key_id is not null then 'ok' else 'alert' end as type
    from
      aws_cloudwatch_log_group
    where
      arn = $1;
  EOQ

  param "log_group_arn" {}
}

query "aws_cloudwatch_log_group_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      creation_time as "Create Date",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_cloudwatch_log_group
    where
      arn = $1;
  EOQ

  param "log_group_arn" {}
}

query "aws_cloudwatch_log_group_tags" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        aws_cloudwatch_log_group
      where
        arn = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
  EOQ

  param "log_group_arn" {}
}

query "aws_cloudwatch_log_group_encryption_details" {
  sql = <<-EOQ
    select
       case when kms_key_id is not null then 'Enabled' else 'Disabled' end as "Encryption",
       kms_key_id as "KMS Key ID"
    from
      aws_cloudwatch_log_group
    where
      arn = $1;
  EOQ

  param "log_group_arn" {}
}

node "aws_cloudwatch_log_group_node" {
  category = category.aws_cloudwatch_log_group

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Creation Time', creation_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_cloudwatch_log_group
    where
      arn = $1
  EOQ

  param "log_group_arn" {}
}

node "aws_cloudwatch_log_group_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      k.arn as id,
      k.title as title,
      jsonb_build_object(
        'ARN', k.arn,
        'ID', k.id,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_kms_key as k on k.arn = g.kms_key_id
    where
      k.region = g.region
      and g.arn =  $1
  EOQ

  param "log_group_arn" {}
}

edge "aws_cloudwatch_log_group_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      g.arn as from_id,
      k.arn as to_id,
      jsonb_build_object(
        'ARN', k.arn,
        'ID', k.id,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_kms_key as k on k.arn = g.kms_key_id
    where
      k.region = g.region
      and g.arn =  $1
  EOQ

  param "log_group_arn" {}
}

node "aws_cloudwatch_log_group_from_cloudtrail_trail_node" {
  category = category.aws_cloudtrail_trail

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', t.arn,
        'Is Logging', t.is_logging,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_cloudtrail_trail as t
    where
      t.log_group_arn = $1
  EOQ

  param "log_group_arn" {}
}

edge "aws_cloudwatch_log_group_from_cloudtrail_trail_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      t.arn as from_id,
      $1 as to_id,
      jsonb_build_object(
        'ARN', t.arn,
        'Is Logging', t.is_logging,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_cloudtrail_trail as t
    where
      t.log_group_arn = $1
  EOQ

  param "log_group_arn" {}
}

node "aws_cloudwatch_log_group_from_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      f.arn as id,
      f.title as title,
      jsonb_build_object(
        'ARN', f.arn,
        'State', f.state,
        'runtime', f.runtime,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_lambda_function as f on f.name = split_part(g.name, '/', 4)
    where
      g.name like '/aws/lambda/%'
      and g.region = f.region
      and g.arn = $1
  EOQ

  param "log_group_arn" {}
}

edge "aws_cloudwatch_log_group_from_lambda_function_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      f.arn as from_id,
      $1 as to_id,
      jsonb_build_object(
        'ARN', f.arn,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_lambda_function as f on f.name = split_part(g.name, '/', 4)
    where
      g.name like '/aws/lambda/%'
      and g.region = f.region
      and g.arn = $1
  EOQ

  param "log_group_arn" {}
}

node "aws_cloudwatch_log_group_from_vpc_flow_logs_node" {
  category = category.aws_vpc_flow_log

  sql = <<-EOQ
    select
      f.flow_log_id as id,
      f.title as title,
      jsonb_build_object(
        'Flow Log ID', f.flow_log_id ,
        'Traffic Type', f.traffic_type,
        'Resource ID', f.resource_id,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_vpc_flow_log as f on g.name = f.log_group_name
    where
      f.region = g.region
      and g.arn = $1
  EOQ

  param "log_group_arn" {}
}

edge "aws_cloudwatch_log_group_from_vpc_flow_logs_edge" {
  title = "logs to"

  sql = <<-EOQ
   select
      f.flow_log_id as from_id,
      $1 as to_id,
      jsonb_build_object(
        'Flow Log ID', f.flow_log_id,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_vpc_flow_log as f on g.name = f.log_group_name
    where
      f.region = g.region
      and g.arn = $1
  EOQ

  param "log_group_arn" {}
}

node "aws_cloudwatch_log_group_from_kinesis_stream_node" {
  category = category.aws_kinesis_stream

  sql = <<-EOQ
    select
      s.stream_arn as id,
      s.stream_name as title,
      jsonb_build_object(
        'ARN', s.stream_arn,
        'Stream Status', s.stream_status,
        'Creation Timestamp', s.stream_creation_timestamp,
        'Account ID', f.account_id,
        'Region', s.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_cloudwatch_log_subscription_filter as f on g.name = f.log_group_name
      right join aws_kinesis_stream as s on s.stream_arn = f.destination_arn
    where
      f.region = g.region
      and g.arn = $1
  EOQ

  param "log_group_arn" {}
}

edge "aws_cloudwatch_log_group_from_kinesis_stream_edge" {
  title = "subscription filter"

  sql = <<-EOQ
    select
      s.stream_arn as from_id,
      $1 as to_id,
      jsonb_build_object(
        'ARN', s.stream_arn,
        'Stream Status', s.stream_status,
        'Creation Timestamp', s.stream_creation_timestamp,
        'Region', s.region,
        'Account ID', f.account_id
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_cloudwatch_log_subscription_filter as f on g.name = f.log_group_name
      right join aws_kinesis_stream as s on s.stream_arn = f.destination_arn
    where
      f.region = g.region
      and g.arn = $1
  EOQ

  param "log_group_arn" {}
}

node "aws_cloudwatch_log_group_subscription_filter_from_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      l.arn as id,
      l.name as title,
      jsonb_build_object(
        'ARN', l.arn,
        'State', l.state,
        'runtime', l.runtime,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_cloudwatch_log_subscription_filter as f on g.name = f.log_group_name
      right join aws_lambda_function as l on l.arn = f.destination_arn
    where
      f.region = g.region
      and g.arn = $1
  EOQ

  param "log_group_arn" {}
}

edge "aws_cloudwatch_log_group_subscription_filter_from_lambda_function_edge" {
  title = "subscription filter"

  sql = <<-EOQ
    select
      l.arn as from_id,
      $1 as to_id,
      jsonb_build_object(
        'ARN', l.arn,
        'State', l.state,
        'runtime', l.runtime,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_cloudwatch_log_subscription_filter as f on g.name = f.log_group_name
      right join aws_lambda_function as l on l.arn = f.destination_arn
    where
      f.region = g.region
      and g.arn = $1
  EOQ

  param "log_group_arn" {}
}