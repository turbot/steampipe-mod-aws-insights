dashboard "aws_rds_db_cluster_snapshot_detail" {

  title         = "AWS RDS DB Cluster Snapshot Detail"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_snapshot_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "snapshot_arn" {
    title = "Select a snapshot:"
    sql   = query.aws_rds_db_cluster_snapshot_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_rds_db_cluster_snapshot_name
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_snapshot_encryption_status
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_snapshot_iam_database_authentication_status
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
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
        query = query.aws_rds_db_cluster_snapshot_overview
        args = {
          arn = self.input.snapshot_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_rds_db_cluster_snapshot_tags
        args = {
          arn = self.input.snapshot_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Attributes"
        query = query.aws_rds_db_cluster_snapshot_attributes
        args = {
          arn = self.input.snapshot_arn.value
        }
      }

    }

  }
}

query "aws_rds_db_cluster_snapshot_input" {
  sql = <<EOQ
    select
      arn as label,
      arn as value
    from
      aws_rds_db_cluster_snapshot
    order by
      arn;
  EOQ
}

query "aws_rds_db_cluster_snapshot_name" {
  sql = <<-EOQ
    select
      db_cluster_snapshot_identifier as value,
      'Snapshot' as label
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_encryption_status" {
  sql = <<-EOQ
    select
      case when storage_encrypted then 'Enabled' else 'Disabled' end as value,
      'Encryption Status' as label,
      case when storage_encrypted then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_iam_database_authentication_status" {
  sql = <<-EOQ
    select
      case when iam_database_authentication_enabled then 'Enabled' else 'Disabled' end as value,
      'IAM Authentication Status' as label,
      case when iam_database_authentication_enabled then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_overview" {
  sql = <<-EOQ
    select
      db_cluster_snapshot_identifier as "Snapshot Name",
      db_cluster_identifier as "Cluster Name",
      create_time as "Create Date",
      engine_version as "Engine Version",
      vpc_id as "VPC ID",
      status as "Status",
      type as "Type",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_rds_db_cluster_snapshot,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_attributes" {
  sql = <<EOQ
    select
      attributes ->> 'AttributeName' as "Name",
      attributes ->> 'AttributeValue' as "Value"
    from
      aws_rds_db_cluster_snapshot,
      jsonb_array_elements(db_cluster_snapshot_attributes) as attributes
    where
      arn = $1;
  EOQ

  param "arn" {}
}
