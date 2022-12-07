dashboard "redshift_snapshot_detail" {

  title         = "AWS Redshift Snapshot Detail"
  documentation = file("./dashboards/redshift/docs/redshift_snapshot_detail.md")

  tags = merge(local.redshift_common_tags, {
    type = "Detail"
  })

  input "snapshot_arn" {
    title = "Select a snapshot:"
    query = query.redshift_snapshot_input
    width = 4
  }

  container {

    card {
      query = query.redshift_snapshot_status
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.redshift_snapshot_type
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.redshift_snapshot_engine
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.redshift_snapshot_backup_size
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.redshift_snapshot_node_type
      width = 2
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      query = query.redshift_snapshot_unencrypted
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

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_key_id as key_arn
          from
            aws_redshift_snapshot
          where
            kms_key_id is not null
            and akas::text = $1;
        EOQ

        args = [self.input.snapshot_arn.value]
      }

      with "redshift_clusters" {
        sql = <<-EOQ
          select
            c.arn as redshift_cluster_arn
          from
            aws_redshift_snapshot as s,
            aws_redshift_cluster as c
          where
            s.cluster_identifier = c.cluster_identifier
            and s.akas::text = $1;
        EOQ

        args = [self.input.snapshot_arn.value]
      }

      nodes = [
        node.kms_key,
        node.redshift_cluster,
        node.redshift_snapshot
      ]

      edges = [
        edge.redshift_cluster_to_redshift_snapshot,
        edge.redshift_snapshot_to_kms_key
      ]

      args = {
        kms_key_arns           = with.kms_keys.rows[*].key_arn
        redshift_cluster_arns  = with.redshift_clusters.rows[*].redshift_cluster_arn
        redshift_snapshot_arns = [self.input.snapshot_arn.value]
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
        query = query.redshift_snapshot_overview
        args = {
          arn = self.input.snapshot_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.redshift_snapshot_tags
        args = {
          arn = self.input.snapshot_arn.value
        }

      }
    }
  }
}

query "redshift_snapshot_input" {
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

query "redshift_snapshot_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      initcap(snapshot_type) as value
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "redshift_snapshot_engine" {
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

query "redshift_snapshot_backup_size" {
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

query "redshift_snapshot_node_type" {
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

query "redshift_snapshot_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_redshift_snapshot
    where
      akas::text = $1;
  EOQ

  param "arn" {}
}

query "redshift_snapshot_unencrypted" {
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

node "redshift_snapshot" {
  category = category.redshift_snapshot

  sql = <<-EOQ
    select
      akas::text as id,
      title,
      jsonb_build_object(
        'Status', status,
        'Cluster Identifier', cluster_identifier,
        'Create Time', cluster_create_time,
        'Type', snapshot_type,
        'Encrypted', encrypted::text,
        'Account ID', account_id,
        'Source Region', source_region
      ) as properties
    from
      aws_redshift_snapshot
    where
      akas::text = any($1);
  EOQ

  param "redshift_snapshot_arns" {}
}

edge "redshift_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      akas::text as from_id,
      kms_key_id as to_id
    from
      aws_redshift_snapshot
    where
      kms_key_id is not null
      and akas::text = any($1);
  EOQ

  param "redshift_snapshot_arns" {}
}

query "redshift_snapshot_overview" {
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

query "redshift_snapshot_tags" {
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
