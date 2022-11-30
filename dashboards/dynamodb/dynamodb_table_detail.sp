dashboard "dynamodb_table_detail" {

  title         = "AWS DynamoDB Table Detail"
  documentation = file("./dashboards/dynamodb/docs/dynamodb_table_detail.md")

  tags = merge(local.dynamodb_common_tags, {
    type = "Detail"
  })

  input "table_arn" {
    title = "Select a table:"
    query = query.dynamodb_table_input
    width = 4
  }

  container {

    card {
      query = query.dynamodb_table_status
      width = 2
      args = {
        arn = self.input.table_arn.value
      }
    }

    card {
      query = query.dynamodb_table_class
      width = 2
      args = {
        arn = self.input.table_arn.value
      }
    }

    card {
      query = query.dynamodb_table_backup_count
      width = 2
      args = {
        arn = self.input.table_arn.value
      }
    }

    card {
      query = query.dynamodb_table_encryption_type
      width = 2
      args = {
        arn = self.input.table_arn.value
      }
    }

    card {
      query = query.dynamodb_table_continuous_backups
      width = 2
      args = {
        arn = self.input.table_arn.value
      }
    }

    card {
      query = query.dynamodb_table_autoscaling_state
      width = 2
      args = {
        arn = self.input.table_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "kms_keys" {
        sql = <<-EOQ
          select
            sse_description ->> 'KMSMasterKeyArn' as key_arn
          from
            aws_dynamodb_table
          where
            arn = $1;
        EOQ

        args = [self.input.table_arn.value]
      }

      with "buckets" {
        sql = <<-EOQ
          select
            b.arn as bucket_arn
          from
            aws_s3_bucket as b,
            aws_dynamodb_table_export as t
          where
            b.name = t.s3_bucket
            and t.table_arn = $1;
        EOQ

        args = [self.input.table_arn.value]
      }

      with "kinesis_streams" {
        sql = <<-EOQ
          select
            s.stream_arn as kinesis_stream_arn
          from
            aws_kinesis_stream as s,
            aws_dynamodb_table as t,
            jsonb_array_elements(t.streaming_destination -> 'KinesisDataStreamDestinations') as d
          where
            d ->> 'StreamArn' = s.stream_arn
            and t.arn = $1;
          EOQ

        args = [self.input.table_arn.value]
      }

      with "dynamodb_backups" {
        sql = <<-EOQ
          select
            b.arn as dbynamodb_backup_arn
          from
            aws_dynamodb_backup as b,
            aws_dynamodb_table as t
          where
            t.arn = b.table_arn
            and t.arn = $1;
        EOQ

        args = [self.input.table_arn.value]
      }

      nodes = [
        node.dynamodb_table,
        node.kms_key,
        node.s3_bucket,
        node.dynamodb_table_to_dynamodb_backup_node,
        node.dynamodb_table_to_kinesis_stream_node
      ]

      edges = [
        edge.dynamodb_table_to_kms_key,
        edge.dynamodb_table_to_s3_bucket,
        edge.dynamodb_table_to_dynamodb_backup,
        edge.dynamodb_table_to_kinesis_stream
      ]

      args = {
        table_arns            = [self.input.table_arn.value]
        bucket_arns           = with.buckets.rows[*].bucket_arn
        key_arns              = with.kms_keys.rows[*].key_arn
        kinesis_stream_arns   = with.kinesis_streams.rows[*].kinesis_stream_arn
        dbynamodb_backup_arns = with.dynamodb_backups.rows[*].dbynamodb_backup_arn
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
        query = query.dynamodb_table_overview
        args = {
          arn = self.input.table_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.dynamodb_table_tags
        args = {
          arn = self.input.table_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Read/Write Capacity"
        width = 6
        query = query.dynamodb_table_read_write_capacity
        args = {
          arn = self.input.table_arn.value
        }
      }

      table {
        title = "Primary Key Schema"
        width = 6
        query = query.dynamodb_table_key_schema
        args = {
          arn = self.input.table_arn.value
        }
      }

      table {
        title = "Point-in-Time Recovery (PITR)"
        width = 12
        query = query.dynamodb_table_point_in_time_recovery
        args = {
          arn = self.input.table_arn.value
        }
      }

    }

  }
}

query "dynamodb_table_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'table_id', table_id
      ) as tags
    from
      aws_dynamodb_table
    order by
      title;
  EOQ
}

query "dynamodb_table_status" {
  sql = <<-EOQ
    select
      initcap(table_status) as value,
      'Status' as label
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "dynamodb_table_size" {
  sql = <<-EOQ
    select
      table_size_bytes as value,
      'Size (Bytes)' as label
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "dynamodb_table_backup_count" {
  sql = <<-EOQ
    select
      count(name) as value,
      'Backup(s)' as label
    from
      aws_dynamodb_backup
    where
      table_arn = $1;
  EOQ

  param "arn" {}
}

query "dynamodb_table_encryption_type" {
  sql = <<-EOQ
    with table_encryption_status as (
      select
        t.name as table_name,
        case
          when t.sse_description ->> 'SSEType' = 'KMS' and k.key_manager = 'AWS' then 'AWS Managed'
          when t.sse_description ->> 'SSEType' = 'KMS' and k.key_manager = 'CUSTOMER' then 'Customer Managed'
          else 'Default'
        end as encryption_type
      from
        aws_dynamodb_table as t
        left join aws_kms_key as k on t.sse_description ->> 'KMSMasterKeyArn' = k.arn
      where
        t.arn = $1
    )
    select
      encryption_type as value,
      'Encryption Type' as label
      -- case when encryption_type is not null then 'ok' else 'alert' end as type
    from
      table_encryption_status
      group by encryption_type;
  EOQ

  param "arn" {}
}

query "dynamodb_table_class" {
  sql = <<-EOQ
    select
      case when table_class is null then 'Standard' else initcap(table_class) end as value,
      'Class' as label
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "dynamodb_table_continuous_backups" {
  sql = <<-EOQ
    select
      case when continuous_backups_status = 'ENABLED' then 'Enabled' else 'Disabled' end as value,
      'Continuous Backups' as label,
      case when continuous_backups_status = 'ENABLED' then 'ok' else 'alert' end as type
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "dynamodb_table_autoscaling_state" {
  sql = <<-EOQ
    with table_with_autoscaling as (
      select
        t.resource_id as resource_id,
        count(t.resource_id) as count
      from
        aws_appautoscaling_target as t where service_namespace = 'dynamodb'
        group by t.resource_id
    )
    select
      case when t.resource_id is null or t.count < 2 then 'Disabled' else 'Enabled' end as value,
      'Auto Scaling' as label,
      case when t.resource_id is null or t.count < 2 then 'alert' else 'ok' end as type
    from
      aws_dynamodb_table as d
      left join table_with_autoscaling as t on concat('table/', d.name) = t.resource_id
    where
      d.arn = $1;
  EOQ

  param "arn" {}
}

edge "dynamodb_table_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      key_arns as to_id,
      table_arns as from_id
    from
      unnest($1::text[]) as key_arns,
      unnest($2::text[]) as table_arns
  EOQ

  param "key_arns" {}
  param "table_arns" {}
}

edge "dynamodb_table_to_s3_bucket" {
  title = "exports to"

  sql = <<-EOQ
    select
      table_arns as from_id,
      bucket_arns as to_id
    from
      unnest($1::text[]) as table_arns,
      unnest($2::text[]) as bucket_arns
  EOQ

  param "table_arns" {}
  param "bucket_arns" {}
}

edge "dynamodb_table_to_dynamodb_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      table_arns as from_id,
      dbynamodb_backup_arns as to_id
    from
      unnest($1::text[]) as table_arns,
      unnest($2::text[]) as dbynamodb_backup_arns
  EOQ

  param "table_arns" {}
  param "dbynamodb_backup_arns" {}
}

edge "dynamodb_table_to_kinesis_stream" {
  title = "streams to"

  sql = <<-EOQ
  select
    table_arns as from_id,
    kinesis_stream_arns as to_id
  from
    unnest($1::text[]) as table_arns,
    unnest($2::text[]) as kinesis_stream_arns
  EOQ

  param "table_arns" {}
  param "kinesis_stream_arns" {}
}

query "dynamodb_table_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      table_id as "Table ID",
      creation_date_time as "Create Date",
      billing_mode as "Billing Mode", -- Represented as Capacity mode in AWS console
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "dynamodb_table_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_dynamodb_table,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "dynamodb_table_key_schema" {
  sql = <<-EOQ
    select
      schema ->> 'AttributeName' as "Attribute Name",
      schema ->> 'KeyType' as "Key Type"
    from
      aws_dynamodb_table,
      jsonb_array_elements(key_schema) as schema
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "dynamodb_table_read_write_capacity" {
  sql = <<-EOQ
    select
      case when read_capacity = 0 then 'On-demand' else read_capacity::text end as "Read Capacity",
      case when write_capacity = 0 then 'On-demand' else write_capacity::text end as "Write Capacity"
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "dynamodb_table_point_in_time_recovery" {
  sql = <<-EOQ
    select
      point_in_time_recovery_description ->> 'PointInTimeRecoveryStatus' as "Status",
      point_in_time_recovery_description ->> 'EarliestRestorableDateTime' as "Earliest Restorable Date",
      point_in_time_recovery_description ->> 'LatestRestorableDateTime' as "Latest Restorable Date"
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}
