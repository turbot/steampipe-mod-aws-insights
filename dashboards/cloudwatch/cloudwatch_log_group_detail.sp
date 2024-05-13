dashboard "cloudwatch_log_group_detail" {

  title         = "AWS CloudWatch Log Group Detail"
  documentation = file("./dashboards/cloudwatch/docs/cloudwatch_log_group_detail.md")

  tags = merge(local.cloudwatch_common_tags, {
    type = "Detail"
  })

  input "log_group_arn" {
    title = "Select a log group:"
    query = query.cloudwatch_log_group_input
    width = 4
  }

  container {

    card {
      query = query.cloudwatch_log_group_retention_in_days
      width = 3
      args  = [self.input.log_group_arn.value]
    }

    card {
      query = query.cloudwatch_log_group_stored_bytes
      width = 3
      args  = [self.input.log_group_arn.value]
    }

    card {
      query = query.cloudwatch_log_group_metric_filter_count
      width = 3
      args  = [self.input.log_group_arn.value]
    }

    card {
      width = 3
      query = query.cloudwatch_log_group_unencrypted
      args  = [self.input.log_group_arn.value]
    }

  }

  with "cloudtrail_trails_for_cloudwatch_log_group" {
    query = query.cloudtrail_trails_for_cloudwatch_log_group
    args  = [self.input.log_group_arn.value]
  }

  with "cloudwatch_log_metric_filters_for_cloudwatch_log_group" {
    query = query.cloudwatch_log_metric_filters_for_cloudwatch_log_group
    args  = [self.input.log_group_arn.value]
  }

  with "kinesis_streams_for_cloudwatch_log_group" {
    query = query.kinesis_streams_for_cloudwatch_log_group
    args  = [self.input.log_group_arn.value]
  }

  with "kms_keys_for_cloudwatch_log_group" {
    query = query.kms_keys_for_cloudwatch_log_group
    args  = [self.input.log_group_arn.value]
  }

  with "lambda_functions_for_cloudwatch_log_group" {
    query = query.lambda_functions_for_cloudwatch_log_group
    args  = [self.input.log_group_arn.value]
  }

  with "vpc_flow_logs_for_cloudwatch_log_group" {
    query = query.vpc_flow_logs_for_cloudwatch_log_group
    args  = [self.input.log_group_arn.value]
  }


  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.cloudtrail_trail
        args = {
          cloudtrail_trail_arns = with.cloudtrail_trails_for_cloudwatch_log_group.rows[*].cloudtrail_trail_arn
        }
      }

      node {
        base = node.cloudwatch_log_group
        args = {
          cloudwatch_log_group_arns = [self.input.log_group_arn.value]
        }
      }

      node {
        base = node.cloudwatch_log_metric_filter
        args = {
          cloudwatch_log_group_arns = [self.input.log_group_arn.value]
        }
      }

      node {
        base = node.kinesis_stream
        args = {
          kinesis_stream_arns = with.kinesis_streams_for_cloudwatch_log_group.rows[*].stream_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_cloudwatch_log_group.rows[*].kms_key_id
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions_for_cloudwatch_log_group.rows[*].lambda_function_arn
        }
      }

      node {
        base = node.vpc_flow_log
        args = {
          vpc_flow_log_ids = with.vpc_flow_logs_for_cloudwatch_log_group.rows[*].flow_log_id
        }
      }

      edge {
        base = edge.cloudtrail_trail_to_cloudwatch_log_group
        args = {
          cloudtrail_trail_arns = with.cloudtrail_trails_for_cloudwatch_log_group.rows[*].cloudtrail_trail_arn
        }
      }

      edge {
        base = edge.cloudwatch_log_group_to_cloudwatch_log_metric_filter_edge
        args = {
          cloudwatch_log_group_arns = [self.input.log_group_arn.value]
        }
      }

      edge {
        base = edge.cloudwatch_log_group_to_kms_key
        args = {
          cloudwatch_log_group_arns = [self.input.log_group_arn.value]
        }
      }

      edge {
        base = edge.kinesis_stream_to_cloudwatch_log_group
        args = {
          kinesis_stream_arns = with.kinesis_streams_for_cloudwatch_log_group.rows[*].stream_arn
        }
      }

      edge {
        base = edge.lambda_function_to_cloudwatch_log_group
        args = {
          lambda_function_arns = with.lambda_functions_for_cloudwatch_log_group.rows[*].lambda_function_arn
        }
      }

      edge {
        base = edge.vpc_flow_log_to_cloudwatch_log_group
        args = {
          vpc_flow_log_ids = with.vpc_flow_logs_for_cloudwatch_log_group.rows[*].flow_log_id
        }
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
        query = query.cloudwatch_log_group_overview
        args  = [self.input.log_group_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.cloudwatch_log_group_tags
        args  = [self.input.log_group_arn.value]

      }
    }

    container {
      width = 6

      table {
        title = "Encryption Details"
        query = query.cloudwatch_log_group_encryption_details
        args  = [self.input.log_group_arn.value]

        column "KMS Key ID" {
          href = "${dashboard.kms_key_detail.url_path}?input.key_arn={{.'KMS Key ID' | @uri}}"
        }
      }

    }

  }

}

# Input queries

query "cloudwatch_log_group_input" {
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

# With queries

query "cloudtrail_trails_for_cloudwatch_log_group" {
  sql = <<-EOQ
    select
      arn as cloudtrail_trail_arn
    from
      aws_cloudtrail_trail
    where
      log_group_arn is not null
      and log_group_arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "cloudwatch_log_metric_filters_for_cloudwatch_log_group" {
  sql = <<-EOQ
    with filtered_log_group as (
      select
        arn,
        name,
        region,
        account_id
      from
        aws_cloudwatch_log_group
      where
        arn = $1
        and region = split_part($1, ':', 4)
        and account_id = split_part($1, ':', 5)
    )
    select
      f.name as log_metric_filter_name
    from
      filtered_log_group g
      left join aws_cloudwatch_log_metric_filter f on g.name = f.log_group_name and g.region = f.region and g.account_id = f.account_id;
  EOQ
}

query "kinesis_streams_for_cloudwatch_log_group" {
  sql = <<-EOQ
    with filtered_log_group as (
      select
        name,
        region,
        account_id
      from
        aws_cloudwatch_log_group
      where
        arn = $1
        and region = split_part($1, ':', 4)
        and account_id = split_part($1, ':', 5)
    ),
    matching_subscription_filters as (
      select
        f.destination_arn
      from
        aws_cloudwatch_log_subscription_filter f
      join
        filtered_log_group g on g.name = f.log_group_name
      where
        f.region = split_part($1, ':', 4)
        and g.account_id = split_part($1, ':', 5)
    )
    select
      s.stream_arn
    from
      aws_kinesis_stream s
    join
      matching_subscription_filters msf on s.stream_arn = msf.destination_arn
    where
      s.account_id = split_part($1, ':', 5)
      and s.region = split_part($1, ':', 4);
  EOQ
}

query "kms_keys_for_cloudwatch_log_group" {
  sql = <<-EOQ
    select
      kms_key_id
    from
      aws_cloudwatch_log_group
    where
      kms_key_id is not null
      and arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "lambda_functions_for_cloudwatch_log_group" {
  sql = <<-EOQ
    with filtered_log_group as (
      select
        name,
        region,
        account_id
      from
        aws_cloudwatch_log_group
      where
        arn = $1
        and name like '/aws/lambda/%'
        and region = split_part($1, ':', 4)
        and account_id = split_part($1, ':', 5)
    )
    select
      f.arn as lambda_function_arn
    from
      aws_lambda_function f
    join
      filtered_log_group efn on f.name = split_part(efn.name, '/', 4)
    where
      f.region = efn.region
      and f.account_id = efn.account_id;
  EOQ
}

query "vpc_flow_logs_for_cloudwatch_log_group" {
  sql = <<-EOQ
    with filtered_log_group as (
      select
        name,
        region,
        account_id
      from
        aws_cloudwatch_log_group
      where
        arn = $1
        and region = split_part($1, ':', 4)
        and account_id = split_part($1, ':', 5)
    )
    select
      distinct f.flow_log_id
    from
      aws_vpc_flow_log f
      join filtered_log_group g on f.log_group_name = g.name and f.region = g.region
    where
      f.log_destination_type = 'cloud-watch-logs'
      and f.account_id = split_part($1, ':', 5);
  EOQ
} 

# Card queries

query "cloudwatch_log_group_retention_in_days" {
  sql = <<-EOQ
    select
      retention_in_days as value,
      'Retention in Days' as label
    from
      aws_cloudwatch_log_group
    where
      arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "cloudwatch_log_group_stored_bytes" {
  sql = <<-EOQ
    select
      stored_bytes as value,
      'Stored Bytes' as label
    from
      aws_cloudwatch_log_group
    where
      arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "cloudwatch_log_group_metric_filter_count" {
  sql = <<-EOQ
    select
      metric_filter_count as value,
      'Metric Filter Count' as label
    from
      aws_cloudwatch_log_group
    where
      arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "cloudwatch_log_group_unencrypted" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_key_id is not null then 'Enabled' else 'Disabled' end as value,
      case when kms_key_id is not null then 'ok' else 'alert' end as type
    from
      aws_cloudwatch_log_group
    where
      arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

# Other detail page queries

query "cloudwatch_log_group_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      creation_time as "Creation Date",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_cloudwatch_log_group
    where
      arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "cloudwatch_log_group_tags" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        aws_cloudwatch_log_group
      where
        arn = $1
        and region = split_part($1, ':', 4)
        and account_id = split_part($1, ':', 5)
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
  EOQ
}

query "cloudwatch_log_group_encryption_details" {
  sql = <<-EOQ
    select
      case when kms_key_id is not null then 'Enabled' else 'Disabled' end as "Encryption",
      kms_key_id as "KMS Key ID"
    from
      aws_cloudwatch_log_group
    where
      arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

