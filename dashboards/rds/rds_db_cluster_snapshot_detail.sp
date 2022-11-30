dashboard "aws_rds_db_cluster_snapshot_detail" {

  title         = "AWS RDS DB Cluster Snapshot Detail"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_snapshot_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "snapshot_arn" {
    title = "Select a snapshot:"
    query = query.aws_rds_db_cluster_snapshot_input
    width = 4
  }

  container {

    card {
      query = query.aws_rds_db_cluster_snapshot_type
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_snapshot_engine
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_snapshot_allocated_storage
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_snapshot_status
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_snapshot_unencrypted
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_snapshot_iam_database_authentication_enabled
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "rds_clusters" {
        sql = <<-EOQ
          select
            c.arn as rds_cluster_arn
          from
            aws_rds_db_cluster as c
            join aws_rds_db_cluster_snapshot as s
            on s.db_cluster_identifier = c.db_cluster_identifier
          where
            s.arn = $1;
        EOQ

        args = [self.input.snapshot_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_key_id as key_arn
          from
            aws_rds_db_cluster_snapshot
          where
            arn = $1;
        EOQ

        args = [self.input.snapshot_arn.value]
      }

      nodes = [
        node.aws_rds_db_cluster_snapshot_nodes,
        node.aws_kms_key_nodes,
        node.aws_rds_db_cluster_nodes
      ]

      edges = [
        edge.aws_rds_db_cluster_snapshot_to_kms_key_edges,
        edge.aws_rds_db_cluster_to_rds_db_cluster_snapshot_edges
      ]

      args = {
        rds_db_cluster_arns          = with.rds_clusters.rows[*].rds_cluster_arn
        key_arns                     = with.kms_keys.rows[*].key_arn
        rds_db_cluster_snapshot_arns = [self.input.snapshot_arn.value]
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
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_cluster_snapshot
    order by
      arn;
  EOQ
}

query "aws_rds_db_cluster_snapshot_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      type as value
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_engine" {
  sql = <<-EOQ
    select
      'Engine' as label,
      engine as  value
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_allocated_storage" {
  sql = <<-EOQ
    select
      'Size (GB)' as label,
      allocated_storage as  value
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_status" {
  sql = <<-EOQ
    select
      status as value,
      'Status' as label,
      case when status = 'available' then 'ok' else 'alert' end as type
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_unencrypted" {
  sql = <<-EOQ
    select
      case when storage_encrypted then 'Enabled' else 'Disabled' end as value,
      'Encryption' as label,
      case when storage_encrypted then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_snapshot_iam_database_authentication_enabled" {
  sql = <<-EOQ
    select
      'IAM Database Authentication' as label,
      case when iam_database_authentication_enabled then 'Enabled' else 'Disabled' end as value,
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
      title as "Title",
      create_time as "Create Date",
      engine_version as "Engine Version",
      license_model as "License Model",
      vpc_id as "VPC ID",
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
  sql = <<-EOQ
    select
      attributes ->> 'AttributeName' as "Name",
      attributes ->> 'AttributeValue' as "Value",
      source_db_cluster_snapshot_arn as "DB Cluster Source Snapshot ARN"
    from
      aws_rds_db_cluster_snapshot,
      jsonb_array_elements(db_cluster_snapshot_attributes) as attributes
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_rds_db_cluster_snapshot_nodes" {
  category = category.rds_db_cluster_snapshot

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Type', type,
        'DB Cluster Identifier', db_cluster_identifier,
        'Create Time', create_time,
        'Encrypted', storage_encrypted::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_cluster_snapshot
    where
      arn = any($1);
  EOQ

  param "rds_db_cluster_snapshot_arns" {}
}

edge "aws_rds_db_cluster_snapshot_to_kms_key_edges" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      db_cluster_snapshot_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as key_arn,
      unnest($2::text[]) as db_cluster_snapshot_arn
  EOQ

  param "key_arns" {}
  param "rds_db_cluster_snapshot_arns" {}
}

