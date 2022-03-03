dashboard "aws_rds_db_snapshot_detail" {
  title = "AWS RDS DB Snapshot Detail"

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_snapshot_arn" {
    title = "Select a DB Snapshot:"
    sql   = query.aws_rds_db_snapshot_input.sql
    width = 4
  }

  container {
    # Assessments

    card {
      width = 2

      query = query.aws_rds_db_snapshot_type
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_snapshot_engine
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_snapshot_status
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_snapshot_unencrypted
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_snapshot_iam_database_authentication_enabled
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      query = query.aws_rds_db_snapshot_in_vpc
      width = 2

      args = {
        arn = self.input.db_snapshot_arn.value
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
        sql   = <<-EOQ
            select
              db_snapshot_identifier as "DB Snapshot Identifier",
              create_time as "Create Time",
              license_model as "License Model",
              engine_version as "Engine Version",
              port as "Port",
              title as "Title",
              region as "Region",
              account_id as "Account ID",
              arn as "ARN"
            from
              aws_rds_db_snapshot
            where
              arn = $1;
          EOQ

        param "arn" {}

        args = {
          arn = self.input.db_snapshot_arn.value
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
            aws_rds_db_snapshot,
            jsonb_array_elements(tags_src) as tag
          where
            arn = $1
          order by
            tag ->> 'Key';
          EOQ

        param "arn" {}

        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }


    }

    container {
      width = 6

      table {
        title = "Storage"
        query = query.aws_rds_db_snapshot_storage
        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }

      table {
        title = "Attributes"
        query = query.aws_rds_db_snapshot_attribute

        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }

    }

  }

}

# Card Queries
query "aws_rds_db_snapshot_input" {
  sql = <<EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_snapshot
    order by
      title;
  EOQ
}

query "aws_rds_db_snapshot_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      type as value
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_snapshot_engine" {
  sql = <<-EOQ
    select
      'Engine' as label,
      engine as  value
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_snapshot_status" {
  sql = <<-EOQ
    select
      status as value,
      'Status' as label,
      case when status = 'available' then 'ok' else 'alert' end as type
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_snapshot_unencrypted" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encrypted then 'Enabled' else 'Disabled' end as value,
      case when encrypted then 'ok' else 'alert' end as type
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_snapshot_iam_database_authentication_enabled" {
  sql = <<-EOQ
    select
      'IAM Database Authentication' as label,
      case when iam_database_authentication_enabled then 'Enabled' else 'Disabled' end as value,
      case when iam_database_authentication_enabled then 'ok' else 'alert' end as type
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_snapshot_in_vpc" {
  sql = <<-EOQ
    select
      'In VPC' as label,
      case when vpc_id is not null then 'Enabled' else 'Disabled' end as value,
      case when vpc_id is not null then 'ok' else 'alert' end as type
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_snapshot_attribute" {
  sql = <<-EOQ
    select
      db_snapshot_identifier as "DB Snapshot Identifier",
      a ->> 'AttributeName' as "Attribute Name",
      a ->> 'AttributeValues' as "Attribute Values"
    from
      aws_rds_db_snapshot,
      jsonb_array_elements(db_snapshot_attributes) as a
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_snapshot_storage" {
  sql = <<-EOQ
    select
      db_snapshot_identifier as "DB Snapshot Identifier",
      storage_type as "Storage Type",
      allocated_storage as "Allocated Storage"
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}
