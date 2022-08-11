dashboard "aws_kms_key_relationships" {
  title         = "AWS KMS Key Relationships"
  documentation = file("./dashboards/kms/docs/kms_key_relationships.md")
  tags = merge(local.kms_common_tags, {
    type = "Relationships"
  })

  input "key_arn" {
    title = "Select a key:"
    query = query.aws_kms_key_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_kms_key_graph_to_key
    args = {
      arn = self.input.key_arn.value
    }
    category "aws_kms_key" {
      href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_dark.svg"))
    }

    category "aws_cloudtrail_trail" {
      href = "${dashboard.aws_cloudtrail_trail_detail.url_path}?input.trail_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cloudtrail_trail_dark.svg"))
    }

    category "aws_ebs_volume" {
      href = "${dashboard.aws_ebs_volume_detail.url_path}?input.volume_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ebs_volume_dark.svg"))
    }

    category "aws_rds_db_cluster_snapshot" {
      color = "blue"
      href  = "${dashboard.aws_rds_db_cluster_snapshot_detail.url_path}?input.snapshot_arn={{.properties.ARN | @uri}}"
    }

    category "aws_rds_db_instance" {
      href = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_dark.svg"))
    }

    category "aws_rds_db_snapshot" {
      color = "blue"
      href  = "${dashboard.aws_rds_db_snapshot_detail.url_path}?input.db_snapshot_arn={{.properties.ARN | @uri}}"
    }

    category "aws_redshift_cluster" {
      href = "${dashboard.aws_redshift_cluster_detail.url_path}?input.cluster_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/redshift_cluster_dark.svg"))
    }

    category "uses" {
      color = "green"
    }
  }
}

query "aws_kms_key_graph_to_key" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      id as id,
      id as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', arn,
        'Key Manager', key_manager,
        'Creation Date', creation_date,
        'Enabled', enabled,
        'Account ID', account_id
      ) as properties
    from
      aws_kms_key
    where
      arn = $1

    -- Cloud Trail - nodes
    union all
    select
      null as from_id,
      null as to_id,
      t.arn as id,
      t.name as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Multi Region Trail', is_multi_region_trail::text,
        'Logging', is_logging::text,
        'Account ID', t.account_id,
        'Home Region', home_region
      ) as properties
    from
      aws_cloudtrail_trail as t
    where
      t.kms_key_id = $1

    -- Cloud Trail  - Edges
    union all
    select
      t.arn as from_id,
      k.id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', t.account_id
      ) as properties
    from
      aws_cloudtrail_trail as t,
      aws_kms_key as k
    where
      t.kms_key_id = k.arn and k.arn = $1


    -- EBS Volume - nodes
    union all
    select
      null as from_id,
      null as to_id,
      volume_id as id,
      volume_id as title,
      'aws_ebs_volume' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'Volume Type', volume_type,
        'State', state,
        'Create Time', create_time,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_ebs_volume as v
    where
      v.kms_key_id = $1

    -- EBS Volume  - Edges
    union all
    select
      volume_id as from_id,
      k.id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', v.account_id
      ) as properties
    from
      aws_ebs_volume as v,
      aws_kms_key as k
    where
      v.kms_key_id = k.arn and k.arn = $1


    -- RDS DB Cluster Snapshot - nodes
    union all
    select
      null as from_id,
      null as to_id,
      db_cluster_snapshot_identifier as id,
      db_cluster_snapshot_identifier as title,
      'aws_rds_db_cluster_snapshot' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'Type', type,
        'Status', status,
        'Create Time', create_time,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_rds_db_cluster_snapshot as s
    where
      s.kms_key_id = $1

    -- RDS DB Cluster Snapshot  - Edges
    union all
    select
      db_cluster_snapshot_identifier as from_id,
      k.id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', s.account_id
      ) as properties
    from
      aws_rds_db_cluster_snapshot as s,
      aws_kms_key as k
    where
      s.kms_key_id = k.arn and k.arn = $1

    -- RDS DB Cluster - nodes
    union all
    select
      null as from_id,
      null as to_id,
      db_cluster_identifier as id,
      db_cluster_identifier as title,
      'aws_rds_db_cluster' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Status', status,
        'Create Time', create_time,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_rds_db_cluster as c
    where
      c.kms_key_id = $1

    -- RDS DB Cluster - Edges
    union all
    select
      db_cluster_identifier as from_id,
      k.id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', c.account_id
      ) as properties
    from
      aws_rds_db_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = k.arn and k.arn = $1

    -- RDS DB Instance - nodes
    union all
    select
      null as from_id,
      null as to_id,
      db_instance_identifier as id,
      db_instance_identifier as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Status', status,
        'Class', class,
        'Engine', engine,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_instance as i
    where
      i.kms_key_id = $1

    -- RDS DB Instance - Edges
    union all
    select
      db_instance_identifier as from_id,
      k.id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', i.account_id
      ) as properties
    from
      aws_rds_db_instance as i,
      aws_kms_key as k
    where
      i.kms_key_id = k.arn and k.arn = $1

    -- RDS DB Instance Snapshot - nodes
    union all
    select
      null as from_id,
      null as to_id,
      db_snapshot_identifier as id,
      db_snapshot_identifier as title,
      'aws_rds_db_snapshot' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'Type', type,
        'Status', status,
        'Create Time', create_time,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_rds_db_snapshot as s
    where
      s.kms_key_id = $1

    -- RDS DB Instance Snapshot - Edges
    union all
    select
      db_snapshot_identifier as from_id,
      k.id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', s.account_id
      ) as properties
    from
      aws_rds_db_snapshot as s,
      aws_kms_key as k
    where
      s.kms_key_id = k.arn and k.arn = $1

    -- Redshift Cluster - nodes
    union all
    select
      null as from_id,
      null as to_id,
      cluster_identifier as id,
      cluster_identifier as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Cluster Availability Status', cluster_availability_status,
        'Cluster Create Time', cluster_create_time,
        'Cluster Status', cluster_status,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_redshift_cluster as c
    where
      c.kms_key_id = $1

    -- Redshift Cluster - Edges
    union all
    select
      cluster_identifier as from_id,
      k.id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', c.account_id
      ) as properties
    from
      aws_redshift_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = k.arn and k.arn = $1
    order by
      category,from_id,to_id
  EOQ

  param "arn" {}
}
