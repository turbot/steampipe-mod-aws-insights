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

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_redshift_snapshot_relationships_graph
      args = {
        arn = self.input.snapshot_arn.value
      }
      category "aws_redshift_snapshot" {}
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
      'aws_redshift_snapshot' as category,
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
      snapshot

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
      snapshot as s
      join aws_kms_key as k on s.kms_key_id = k.arn

    -- To KMS keys (edge)
    union all
    select
      s.snapshot_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'redshift_snapshot_to_kms_key' as category,
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
      jsonb_build_object(
        'ARN', c.arn,
        'Status', c.cluster_status,
        'Availability Zone', c.availability_zone,
        'Create Time', c.cluster_create_time,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      snapshot as s
      join aws_redshift_cluster as c on s.cluster_identifier = c.cluster_identifier
        and s.account_id = c.account_id
        and s.region = c.region

    -- From Redshift cluster (edge)
    union all
    select
      c.cluster_identifier as from_id,
      s.snapshot_identifier as to_id,
      null as id,
      'cluster' as title,
      'redshift_cluster_to_redshift_snapshot' as category,
      jsonb_build_object(
        'Cluster Identifier', c.cluster_identifier,
        'Cluster Snapshot Identifier', s.snapshot_identifier,
        'Status', s.status,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      snapshot as s
      join aws_redshift_cluster as c on s.cluster_identifier = c.cluster_identifier
        and s.account_id = c.account_id
        and s.region = c.region

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
