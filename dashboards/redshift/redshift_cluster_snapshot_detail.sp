dashboard "aws_redshift_snapshot_detail" {

  title         = "AWS Redshift Snapshot Detail"
  documentation = file("./dashboards/redshift/docs/redshift_snapshot_detail.md")

  tags = merge(local.redshift_common_tags, {
    type = "Detail"
  })

  input "snapshot_arn" {
    title = "Select a snapshot:"
    sql   = query.aws_redshift_snapshot_input.sql
    width = 4
  }

  container {

    card {
      query = query.aws_redshift_snapshot_type
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_redshift_snapshot_engine
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_redshift_snapshot_backup_size
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_redshift_snapshot_node_type
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_redshift_snapshot_status
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.aws_redshift_snapshot_unencrypted
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_redshift_snapshot_relationships_graph
      args = {
        arn = self.input.snapshot_arn.value
      }

      category "snapshot" {
      }

      category "aws_redshift_cluster" {
        href = "/aws_insights.dashboard.aws_redshift_cluster_detail.url_path?input.cluster_arn={{.properties.ARN | @uri}}"
        icon = local.aws_redshift_cluster_icon
      }

      category "kms_key" {
        href = "/aws_insights.dashboard.aws_kms_key_detail.url_path?input.key_arn={{.properties.ARN | @uri}}"
        icon = local.aws_kms_key_icon
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
        query = query.aws_redshift_snapshot_overview
        args = {
          arn = self.input.snapshot_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_redshift_snapshot_tags
        args = {
          arn = self.input.snapshot_arn.value
        }

      }
    }
  }
}

query "aws_redshift_snapshot_input" {
  sql = <<-EOQ
    select
      title as label,
      akas::text as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_redshift_snapshot
    order by
      akas;
  EOQ
}

query "aws_redshift_snapshot_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      snapshot_type as value
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_snapshot_engine" {
  sql = <<-EOQ
    select
      'Engine Version' as label,
      engine_full_version as  value
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_snapshot_backup_size" {
  sql = <<-EOQ
    select
      'Size (GB)' as label,
      total_backup_size_in_mega_bytes as  value
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_snapshot_node_type" {
  sql = <<-EOQ
    select
      'Node Type' as label,
      node_type as  value
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_snapshot_status" {
  sql = <<-EOQ
    select
      status as value,
      'Status' as label,
      case when status = 'available' then 'ok' else 'alert' end as type
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_snapshot_unencrypted" {
  sql = <<-EOQ
    select
      case when encrypted or encrypted_with_hsm then 'Enabled' else 'Disabled' end as value,
      'Encryption' as label,
      case when encrypted or encrypted_with_hsm then 'ok' else 'alert' end as "type"
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_snapshot_relationships_graph" {
  sql = <<-EOQ
    with snapshot as(
      select
        *
      from
        aws_redshift_snapshot
      where
        akas::text = $1
    )
    -- Redshift cluster snapshot (node)
    select
      null as from_id,
      null as to_id,
      title as id,
      title,
      'snapshot' as category,
      jsonb_build_object( 'Status', status, 'Cluster Identifier', cluster_identifier, 'Create Time', cluster_create_time, 'Type', snapshot_type, 'Encrypted', encrypted::text, 'Account ID', account_id, 'Source Region', source_region ) as properties 
    from
      snapshot

    -- To KMS Keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.id as id,
      coalesce(k.aliases #>> '{0,AliasName}', k.id) as title,
      'kms_key' as category,
      jsonb_build_object( 'ARN', k.arn, 'Rotation Enabled', k.key_rotation_enabled::text, 'Account ID', k.account_id, 'Region', k.region ) as properties 
    from
      snapshot as s 
      join
        aws_kms_key as k 
        on s.kms_key_id = k.arn

    -- To KMS keys (edge)
    union all
    select
      s.snapshot_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Cluster Snapshot Identifier', s.snapshot_identifier,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      snapshot as s
      join aws_kms_key as k on s.kms_key_id = k.arn

    -- From Redshift cluster (node)
    union all
    select
      null as from_id,
      null as to_id,
      c.cluster_identifier as id,
      c.title as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object( 'ARN', c.arn, 'Status', c.cluster_status, 'Availability Zone', c.availability_zone, 'Create Time', c.cluster_create_time, 'Account ID', c.account_id, 'Region', c.region ) as properties 
    from
      snapshot as s 
      join
        aws_redshift_cluster as c 
        on s.cluster_identifier = c.cluster_identifier 
        and s.account_id = c.account_id 
        and s.region = c.region

    -- From Redshift cluster (edge)
    union all
    select
      c.cluster_identifier as from_id,
      s.snapshot_identifier as to_id,
      null as id,
      'has snapshot' as title,
      'uses' as category,
      jsonb_build_object( 'Cluster Identifier', c.cluster_identifier, 'Cluster Snapshot Identifier', s.snapshot_identifier, 'Status', s.status, 'Account ID', c.account_id, 'Region', c.region ) as properties 
    from
      snapshot as s 
      join
        aws_redshift_cluster as c 
        on s.cluster_identifier = c.cluster_identifier 
        and s.account_id = c.account_id 
        and s.region = c.region
        
    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_redshift_snapshot_overview" {
  sql = <<-EOQ
    select
      snapshot_identifier as "Snapshot Name",
      cluster_identifier as "Cluster Name",
      title as "Title",
      snapshot_create_time as "Create Date",
      engine_full_version as "Engine Version",
      vpc_id as "VPC ID",
      manual_snapshot_remaining_days as "Manual Snapshot Remaining Days",
      availability_zone as "Availability Zone",
      region as "Region",
      account_id as "Account ID"
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_snapshot_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_redshift_snapshot,
      jsonb_array_elements(tags_src) as tag
    where
      akas::text = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}
