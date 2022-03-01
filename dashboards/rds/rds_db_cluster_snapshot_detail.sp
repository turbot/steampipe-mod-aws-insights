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

dashboard "aws_rds_db_cluster_snapshot_detail" {
  title = "AWS RDS DB Cluster Snapshot Detail"

  tags = merge(local.rds_common_tags, {
    type     = "Detail"
    category = "Snapshot"
  })

  input "arn" {
    title = "Select a snapshot:"
    sql   = query.aws_rds_db_cluster_snapshot_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      query = query.aws_rds_db_cluster_snapshot_name
      width = 2

      args = {
        arn = self.input.arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_cluster_snapshot_encryption_status
      args = {
        arn = self.input.arn.value
      }
    }

    # Assessments
    card {
      width = 2

      query = query.aws_rds_db_cluster_snapshot_iam_database_authentication_status
      args = {
        arn = self.input.arn.value
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
            db_cluster_snapshot_identifier as "Snapshot Name",
            db_cluster_identifier as "Cluster Name",
            create_time as "Create Date",
            vpc_id as "VPC ID",
            status as "Status",
            type as "Type",
            arn as "ARN",
            account_id as "Account ID"
          from
            aws_rds_db_cluster_snapshot
          where
            arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.arn.value
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
            aws_rds_db_cluster_snapshot,
            jsonb_array_elements(tags_src) as tag
          where
            arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.arn.value
        }

      }
    }

  }
}
