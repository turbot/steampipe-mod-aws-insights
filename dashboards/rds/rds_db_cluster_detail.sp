dashboard "aws_rds_db_cluster_detail" {

  title = "AWS RDS DB Cluster Detail"
  #documentation = file("./dashboards/rds/docs/rds_db_cluster_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "cluster_arn" {
    title = "Select a cluster:"
    query = query.aws_rds_db_cluster_input
    width = 4
  }

  container {

    card {
      query = query.aws_rds_db_cluster_unencrypted
      width = 2
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_logging_disabled
      width = 2
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_no_deletion_protection
      width = 2
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_status
      width = 2
      args = {
        arn = self.input.cluster_arn.value
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
        query = query.aws_rds_db_cluster_overview
        args = {
          arn = self.input.cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_rds_db_cluster_tags
        args = {
          arn = self.input.cluster_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Attributes"
        # query = query.aws_rds_db_cluster_attributes
        args = {
          arn = self.input.cluster_arn.value
        }
      }

    }

  }
}

query "aws_rds_db_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_cluster
    order by
      arn;
  EOQ
}

query "aws_rds_db_cluster_unencrypted" {
  sql = <<-EOQ
    select
      case when storage_encrypted then 'Enabled' else 'Disabled' end as value,
      'Encryption' as label,
      case when storage_encrypted then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_logging_disabled" {
  sql = <<-EOQ
    select
      case when enabled_cloudwatch_logs_exports is not null then 'Enabled' else 'Disabled' end as value,
      'Logging' as label,
      case when enabled_cloudwatch_logs_exports is not null then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_no_deletion_protection" {
  sql = <<-EOQ
    select
      case when deletion_protection then 'Enabled' else 'Disabled' end as value,
      'Deletion Protection' as label,
      case when deletion_protection then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_status" {
  sql = <<-EOQ
    select
      status as value,
      'Status' as label,
      case when status = 'available' then 'ok' else 'alert' end as type
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_overview" {
  sql = <<-EOQ
    select
      db_cluster_identifier as "Cluster Name",
      title as "Title",
      create_time as "Create Date",
      engine_version as "Engine Version",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_rds_db_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_attributes" {
  sql = <<-EOQ
    select
      attributes ->> 'AttributeName' as "Name",
      attributes ->> 'AttributeValue' as "Value",
      source_db_cluster_arn as "DB Cluster Source Snapshot ARN"
    from
      aws_rds_db_cluster,
      jsonb_array_elements(db_cluster_attributes) as attributes
    where
      arn = $1;
  EOQ

  param "arn" {}
}
