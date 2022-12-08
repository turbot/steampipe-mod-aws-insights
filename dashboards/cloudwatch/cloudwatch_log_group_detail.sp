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
      width = 2
      args = {
        log_group_arn = self.input.log_group_arn.value
      }
    }

    card {
      query = query.cloudwatch_log_group_stored_bytes
      width = 2
      args = {
        log_group_arn = self.input.log_group_arn.value
      }
    }

    card {
      query = query.cloudwatch_log_group_metric_filter_count
      width = 2
      args = {
        log_group_arn = self.input.log_group_arn.value
      }
    }

    card {
      width = 2
      query = query.cloudwatch_log_group_unencrypted
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

      with "cloudtrail_trails" {
        sql = <<-EOQ
          select
            arn as cloudtrail_trail_arn
          from
            aws_cloudtrail_trail
          where
            log_group_arn is not null
            and log_group_arn = $1;
        EOQ

        args = [self.input.log_group_arn.value]
      }

      with "cloudwatch_log_metric_filters" {
        sql = <<-EOQ
          select
            f.name as log_metric_filter_name
          from
            aws_cloudwatch_log_group as g
            left join aws_cloudwatch_log_metric_filter as f on g.name = f.log_group_name
          where
            f.region = g.region
            and g.arn = $1;
        EOQ

        args = [self.input.log_group_arn.value]
      }

      with "kinesis_streams" {
        sql = <<-EOQ
          select
            s.stream_arn
          from
            aws_cloudwatch_log_group as g,
            aws_cloudwatch_log_subscription_filter as f,
            aws_kinesis_stream as s
          where
            f.region = g.region
            and g.name = f.log_group_name
            and s.stream_arn = f.destination_arn
            and g.arn = $1;
        EOQ

        args = [self.input.log_group_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_key_id
          from
            aws_cloudwatch_log_group
          where
            kms_key_id is not null
            and arn = $1;
        EOQ

        args = [self.input.log_group_arn.value]
      }

      with "lambda_functions" {
        sql = <<-EOQ
          select
            f.arn as lambda_function_arn
          from
            aws_cloudwatch_log_group as g
            left join aws_lambda_function as f on f.name = split_part(g.name, '/', 4)
          where
            g.name like '/aws/lambda/%'
            and g.region = f.region
            and g.arn = $1;
        EOQ

        args = [self.input.log_group_arn.value]
      }

      with "vpc_flow_logs" {
        sql = <<-EOQ
          select
            distinct f.flow_log_id
          from
            aws_cloudwatch_log_group as g,
            aws_vpc_flow_log as f
          where
            f.log_group_name = g.name
            and f.log_destination_type = 'cloud-watch-logs'
            and f.region = g.region
            and g.arn = $1;
        EOQ

        args = [self.input.log_group_arn.value]
      }

      nodes = [
        node.cloudtrail_trail,
        node.cloudwatch_log_group,
        node.cloudwatch_log_metric_filter,
        node.kinesis_stream,
        node.kms_key,
        node.lambda_function,
        node.vpc_flow_log
      ]

      edges = [
        edge.cloudtrail_trail_to_cloudwatch_log_group,
        edge.cloudwatch_log_group_to_kms_key,
        edge.cloudwatch_log_group_to_log_metric_filter_edge,
        edge.kinesis_stream_to_cloudwatch_log_group,
        edge.lambda_function_to_cloudwatch_log_group,
        edge.vpc_flow_log_to_cloudwatch_log_group
      ]

      args = {
        cloudtrail_trail_arns     = with.cloudtrail_trails.rows[*].cloudtrail_trail_arn
        cloudwatch_log_group_arns = [self.input.log_group_arn.value]
        kinesis_stream_arns       = with.kinesis_streams.rows[*].stream_arn
        kms_key_arns              = with.kms_keys.rows[*].kms_key_id
        lambda_function_arns      = with.lambda_functions.rows[*].lambda_function_arn
        log_metric_filter_name    = with.cloudwatch_log_metric_filters.rows[*].log_metric_filter_name
        vpc_flow_log_ids          = with.vpc_flow_logs.rows[*].flow_log_id
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
        args = {
          log_group_arn = self.input.log_group_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.cloudwatch_log_group_tags
        args = {
          log_group_arn = self.input.log_group_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Encryption Details"
        query = query.cloudwatch_log_group_encryption_details
        args = {
          log_group_arn = self.input.log_group_arn.value
        }

        column "KMS Key ID" {
          href = "${dashboard.kms_key_detail.url_path}?input.key_arn={{.'KMS Key ID' | @uri}}"
        }
      }

    }

  }

}

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

query "cloudwatch_log_group_retention_in_days" {
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

query "cloudwatch_log_group_stored_bytes" {
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

query "cloudwatch_log_group_metric_filter_count" {
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

query "cloudwatch_log_group_unencrypted" {
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

query "cloudwatch_log_group_overview" {
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

query "cloudwatch_log_group_tags" {
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

query "cloudwatch_log_group_encryption_details" {
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

node "cloudwatch_log_group" {
  category = category.cloudwatch_log_group

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Creation Time', creation_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_cloudwatch_log_group
    where
      arn = any($1 ::text[]);
  EOQ

  param "cloudwatch_log_group_arns" {}
}