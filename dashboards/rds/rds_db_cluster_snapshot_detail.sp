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
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_rds_db_cluster_snapshot_relationships_graph
      args = {
        arn = self.input.snapshot_arn.value
      }
      category "aws_rds_db_cluster_snapshot" {}
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


query "aws_rds_db_cluster_snapshot_relationships_graph" {
  sql = <<-EOQ
    -- RDS DB cluster snapshot (node)
    select
      null as from_id,
      null as to_id,
      db_cluster_snapshot_identifier as id,
      title,
      'aws_rds_db_cluster_snapshot' as category,
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
      arn = $1

    -- To KMS keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.id as id,
      COALESCE(k.aliases #>> '{0,AliasName}', k.id) as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Rotation Enabled', k.key_rotation_enabled::text,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_cluster_snapshot as s
      join aws_kms_key as k on s.kms_key_id = k.arn
    where
      s.arn = $1

    -- To KMS keys (edge)
    union all
    select
      s.db_cluster_snapshot_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'rds_db_cluster_snapshot_to_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'DB Cluster Snapshot Identifier', s.db_cluster_snapshot_identifier,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_cluster_snapshot as s
      join aws_kms_key as k on s.kms_key_id = k.arn
    where
      s.arn = $1


    -- From RDS DB cluster (node)
    union all
    select
      null as from_id,
      null as to_id,
      c.db_cluster_identifier as id,
      c.title as title,
      'aws_rds_db_cluster' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Status', c.status,
        'Availability Zones', c.availability_zones::text,
        'Create Time', c.create_time,
        'Is Multi AZ', c.multi_az::text,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_rds_db_cluster_snapshot as s
      join aws_rds_db_cluster as c on s.db_cluster_identifier = c.db_cluster_identifier
        and s.account_id = c.account_id
        and s.region = c.region
    where
      s.arn = $1

    -- From RDS DB cluster (edge)
    union all
    select
      c.db_cluster_identifier as from_id,
      s.db_cluster_snapshot_identifier as to_id,
      null as id,
      'snapshot' as title,
      'rds_db_cluster_to_rds_db_cluster_snapshot' as category,
      jsonb_build_object(
        'DB Cluster Identifier', c.db_cluster_identifier,
        'DB Cluster Snapshot Identifier', s.db_cluster_snapshot_identifier,
        'Status', s.status,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_rds_db_cluster_snapshot as s
      join aws_rds_db_cluster as c on s.db_cluster_identifier = c.db_cluster_identifier
        and s.account_id = c.account_id
        and s.region = c.region
    where
      s.arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
