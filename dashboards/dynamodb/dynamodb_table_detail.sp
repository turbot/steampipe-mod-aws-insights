query "aws_dynamodb_table_input" {
  sql = <<EOQ
    select
      arn as label,
      arn as value
    from
      aws_dynamodb_table
    order by
      arn;
  EOQ
}

query "aws_dynamodb_table_name" {
  sql = <<-EOQ
    select
      name as "Table Name"
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_dynamodb_table_items_count" {
  sql = <<-EOQ
    select
      item_count as value,
      'Items' as label,
      case item_count when 0 then 'alert' else 'ok' end as type
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_dynamodb_table_encryption_type" {
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
      'Encryption Type' as label,
      case when encryption_type is not null then 'ok' else 'alert' end as type
    from
      table_encryption_status
      group by encryption_type;
  EOQ

  param "arn" {}
}

query "aws_dynamodb_table_continuous_backup_status" {
  sql = <<-EOQ
    select
      case when continuous_backups_status = 'ENABLED' then 'Enabled' else 'Disabled' end as value,
      'Continuous Backup Status' as label,
      case when continuous_backups_status = 'ENABLED' then 'ok' else 'alert' end as type
    from
      aws_dynamodb_table
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_dynamodb_table_autoscaling_status" {
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
      'Autoscaling Status' as label,
      case when t.resource_id is null or t.count < 2 then 'alert' else 'ok' end as type
    from
      aws_dynamodb_table as d
      left join table_with_autoscaling as t on concat('table/', d.name) = t.resource_id
    where
      d.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_dynamodb_table_backuo_plan_protection_status" {
  sql = <<-EOQ
    select
      t.name as table_name,
      t.arn as arn,
      last_backup_time
    from
      aws_dynamodb_table as t
      left join aws_backup_protected_resource as b on t.arn = b.resource_arn
    where
      t.arn = $1 and b.resource_type = 'DynamoDB';
  EOQ

  param "arn" {}
}

dashboard "aws_dynamodb_table_detail" {
  title = "AWS DynamoDB Table Detail"

  tags = merge(local.dynamodb_common_tags, {
    type = "Detail"
  })

  input "table_arn" {
    title = "Select a table:"
    sql   = query.aws_dynamodb_table_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.aws_dynamodb_table_name
      args = {
        arn = self.input.table_arn.value
      }
    }

    # Assessments
    card {
      width = 2

      query = query.aws_dynamodb_table_items_count
      args = {
        arn = self.input.table_arn.value
      }
    }

    card {
      query = query.aws_dynamodb_table_autoscaling_status
      width = 2

      args = {
        arn = self.input.table_arn.value
      }
    }

    card {
      query = query.aws_dynamodb_table_continuous_backup_status
      width = 2

      args = {
        arn = self.input.table_arn.value
      }
    }

    card {
      query = query.aws_dynamodb_table_encryption_type
      width = 2

      args = {
        arn = self.input.table_arn.value
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

        sql = <<-EOQ
          select
            name as "Name",
            creation_date_time as "Create Date",
            table_status as "Status",
            table_id as "Table ID",
            billing_mode as "Billing Mode",
            arn as "ARN",
            account_id as "Account ID"
          from
            aws_dynamodb_table
          where
           arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.table_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
            select
              tag ->> 'Key' as "Key",
              tag ->> 'Value' as "Value"
            from
              aws_dynamodb_table,
              jsonb_array_elements(tags_src) as tag
            where
              arn = $1;
          EOQ

        param "arn" {}

        args = {
          arn = self.input.table_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Backup Plan Protection"
        sql   = <<-EOQ
          select
            t.name as "Table Name",
            t.arn as "ARN",
            last_backup_time as "Last Backup Time"
          from
            aws_dynamodb_table as t
            left join aws_backup_protected_resource as b on t.arn = b.resource_arn
          where
            t.arn = $1 and b.resource_type = 'DynamoDB';
        EOQ

        param "arn" {}

        args = {
          arn = self.input.table_arn.value
        }
      }

      table {
        title = "Point In Time Recovery"
        sql   = <<-EOQ
          select
            point_in_time_recovery_description ->> 'EarliestRestorableDateTime' as "Earliest Restorable Date",
            point_in_time_recovery_description ->> 'LatestRestorableDateTime' as "Latest Restorable Date",
            point_in_time_recovery_description ->> 'PointInTimeRecoveryStatus' as "Status"
          from
            aws_dynamodb_table as t
          where
            t.arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.table_arn.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Key Schema"
        width = 6

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

        args = {
          arn = self.input.table_arn.value
        }
      }

      table {
        title = "Read/Write Capacity"
        width = 6

        sql = <<-EOQ
            select
              read_capacity as "Read Capacity",
              write_capacity as "Write Capacity"
            from
              aws_dynamodb_table,
              jsonb_array_elements(key_schema) as schema
            where
              arn = $1;
          EOQ

        param "arn" {}

        args = {
          arn = self.input.table_arn.value
        }
      }
    }

  }
}
