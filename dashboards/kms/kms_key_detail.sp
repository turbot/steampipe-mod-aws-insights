dashboard "aws_kms_key_detail" {

  title         = "AWS KMS Key Detail"
  documentation = file("./dashboards/kms/docs/kms_key_detail.md")

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })


  input "key_arn" {
    title = "Select a key:"
    sql   = query.aws_kms_key_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_kms_key_type
      args = {
        arn = self.input.key_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_kms_key_origin
      args = {
        arn = self.input.key_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_kms_key_state
      args = {
        arn = self.input.key_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_kms_key_rotation_enabled
      args = {
        arn = self.input.key_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_kms_key_relationships_graph
      args = {
        arn = self.input.key_arn.value
      }
      category "aws_kms_key" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_light.svg"))
      }

      category "aws_cloudtrail_trail" {
        href = "${dashboard.aws_cloudtrail_trail_detail.url_path}?input.trail_arn={{.properties.ARN | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cloudtrail_trail_light.svg"))
      }

      category "aws_ebs_volume" {
        href = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ebs_volume_light.svg"))
      }

      category "aws_rds_db_cluster" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_cluster_light.svg"))
      }

      category "aws_rds_db_cluster_snapshot" {
        color = "blue"
        href  = "${dashboard.aws_rds_db_cluster_snapshot_detail.url_path}?input.snapshot_arn={{.properties.ARN | @uri}}"
      }

      category "aws_rds_db_instance" {
        href = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.ARN | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_light.svg"))
      }

      category "aws_rds_db_snapshot" {
        color = "blue"
        href  = "${dashboard.aws_rds_db_snapshot_detail.url_path}?input.db_snapshot_arn={{.properties.ARN | @uri}}"
      }

      category "aws_redshift_cluster" {
        // cyclic dependency prevents use of url_path, hardcode for now
        # href = "${dashboard.aws_redshift_cluster_detail.url_path}?input.cluster_arn={{.properties.ARN | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/redshift_cluster_light.svg"))
         href = "/aws_insights.dashboard.aws_redshift_cluster_detail?input.cluster_arn={{.properties.'ARN' | @uri}}"
      }

      category "uses" {
        color = "green"
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
        query = query.aws_kms_key_overview
        args = {
          arn = self.input.key_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_kms_key_tags
        args = {
          arn = self.input.key_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Key Age"
        query = query.aws_kms_key_age
        args = {
          arn = self.input.key_arn.value
        }
      }

    }

  }

  table {
    title = "Policy"
    query = query.aws_kms_key_policy
    args = {
      arn = self.input.key_arn.value
    }
  }

  table {
    title = "Key Aliases"
    query = query.aws_kms_key_aliases
    args = {
      arn = self.input.key_arn.value
    }
  }

}

query "aws_kms_key_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_kms_key
    order by
      title;
  EOQ
}

query "aws_kms_key_type" {
  sql = <<-EOQ
    select
      'Key Manager' as label,
      key_manager as value
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_origin" {
  sql = <<-EOQ
    select
      'Origin' as label,
      origin as value
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_state" {
  sql = <<-EOQ
    select
      'State' as label,
      key_state as value,
      case when key_state = 'Enabled' then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_rotation_enabled" {
  sql = <<-EOQ
    select
      'Key Rotation' as label,
      case
        when key_rotation_enabled is null then 'N/A'
        when key_rotation_enabled then 'Enabled' else 'Disabled' end as value,
      case when key_rotation_enabled or key_rotation_enabled is null then 'ok' else 'alert' end as type
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_age" {
  sql = <<-EOQ
    select
      creation_date as "Creation Date",
      deletion_date as "Deletion Date",
      extract(day from deletion_date - current_date)::int as "Deleting After Days"
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_aliases" {
  sql = <<-EOQ
    select
      p ->> 'AliasArn' as "Alias Arn",
      p ->> 'AliasName' as "Alias Name",
      p ->> 'LastUpdatedDate' as "Last Updated Date",
      p ->> 'TargetKeyId' as "Target Key ID"
    from
      aws_kms_key,
      jsonb_array_elements(aliases) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_policy" {
  sql = <<-EOQ
    select
      p ->> 'Sid' as "Sid",
      p ->> 'Effect' as "Effect",
      p -> 'Principal' as "Principal",
      p -> 'Action' as "Action",
      p -> 'Resource' as "Resource",
      p -> 'Condition' as "Condition"
    from
      aws_kms_key,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      id as id,
      id as title,
      'aws_kms_key' as category,
      jsonb_build_object( 'ARN', arn, 'Key Manager', key_manager, 'Creation Date', creation_date, 'Enabled', enabled, 'Account ID', account_id ) as properties
    from
      aws_kms_key
    where
      arn = $1

    -- From Cloud Trails (node)
    union all
    select
      null as from_id,
      null as to_id,
      t.arn as id,
      t.name as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object( 'ARN', t.arn, 'Multi Region Trail', is_multi_region_trail::text, 'Logging', is_logging::text, 'Account ID', t.account_id, 'Home Region', home_region ) as properties
    from
      aws_cloudtrail_trail as t
    where
      t.kms_key_id = $1

    -- From Cloud Trails (edge)
    union all
    select
      t.arn as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', t.account_id ) as properties
    from
      aws_cloudtrail_trail as t,
      aws_kms_key as k
    where
      t.kms_key_id = k.arn
      and k.arn = $1

    -- EBS Volumes (node)
    union all
    select
      null as from_id,
      null as to_id,
      volume_id as id,
      volume_id as title,
      'aws_ebs_volume' as category,
      jsonb_build_object( 'ARN', v.arn, 'Volume Type', volume_type, 'State', state, 'Create Time', create_time, 'Account ID', v.account_id, 'Region', v.region ) as properties
    from
      aws_ebs_volume as v
    where
      v.kms_key_id = $1

    -- EBS Volumes (edge)
    union all
    select
      volume_id as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', v.account_id ) as properties
    from
      aws_ebs_volume as v,
      aws_kms_key as k
    where
      v.kms_key_id = k.arn
      and k.arn = $1


    -- RDS DB Cluster Snapshots (node)
    union all
    select
      null as from_id,
      null as to_id,
      db_cluster_snapshot_identifier as id,
      db_cluster_snapshot_identifier as title,
      'aws_rds_db_cluster_snapshot' as category,
      jsonb_build_object( 'ARN', s.arn, 'Type', type, 'Status', status, 'Create Time', create_time, 'Account ID', s.account_id, 'Region', s.region ) as properties
    from
      aws_rds_db_cluster_snapshot as s
    where
      s.kms_key_id = $1

    -- RDS DB Cluster Snapshots (edge)
    union all
    select
      db_cluster_snapshot_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', s.account_id ) as properties
    from
      aws_rds_db_cluster_snapshot as s,
      aws_kms_key as k
    where
      s.kms_key_id = k.arn
      and k.arn = $1

    -- RDS DB Clusters (node)
    union all
    select
      null as from_id,
      null as to_id,
      db_cluster_identifier as id,
      db_cluster_identifier as title,
      'aws_rds_db_cluster' as category,
      jsonb_build_object( 'ARN', c.arn, 'Status', status, 'Create Time', create_time, 'Account ID', c.account_id, 'Region', c.region ) as properties
    from
      aws_rds_db_cluster as c
    where
      c.kms_key_id = $1

    -- RDS DB Clusters (edge)
    union all
    select
      db_cluster_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_rds_db_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = k.arn
      and k.arn = $1

    -- RDS DB Instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      db_instance_identifier as id,
      db_instance_identifier as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object( 'ARN', i.arn, 'Status', status, 'Class', class, 'Engine', engine, 'Account ID', i.account_id, 'Region', i.region ) as properties
    from
      aws_rds_db_instance as i
    where
      i.kms_key_id = $1

    -- RDS DB Instances (edge)
    union all
    select
      db_instance_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', i.account_id ) as properties
    from
      aws_rds_db_instance as i,
      aws_kms_key as k
    where
      i.kms_key_id = k.arn
      and k.arn = $1

    -- RDS DB Instance Snapshots (node)
    union all
    select
      null as from_id,
      null as to_id,
      db_snapshot_identifier as id,
      db_snapshot_identifier as title,
      'aws_rds_db_snapshot' as category,
      jsonb_build_object( 'ARN', s.arn, 'Type', type, 'Status', status, 'Create Time', create_time, 'Account ID', s.account_id, 'Region', s.region ) as properties
    from
      aws_rds_db_snapshot as s
    where
      s.kms_key_id = $1

    -- RDS DB Instance Snapshots (edge)
    union all
    select
      db_snapshot_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', s.account_id ) as properties
    from
      aws_rds_db_snapshot as s,
      aws_kms_key as k
    where
      s.kms_key_id = k.arn
      and k.arn = $1

    -- Redshift Clusters (node)
    union all
    select
      null as from_id,
      null as to_id,
      cluster_identifier as id,
      cluster_identifier as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object( 'ARN', c.arn, 'Cluster Availability Status', cluster_availability_status, 'Cluster Create Time', cluster_create_time, 'Cluster Status', cluster_status, 'Account ID', c.account_id, 'Region', c.region ) as properties
    from
      aws_redshift_cluster as c
    where
      c.kms_key_id = $1

    -- Redshift Clusters (edge)
    union all
    select
      cluster_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_redshift_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = k.arn
      and k.arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_kms_key_overview" {
  sql = <<-EOQ
    select
      id as "ID",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_kms_key
    where
      arn = $1
    EOQ

  param "arn" {}
}

query "aws_kms_key_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_kms_key,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}
