dashboard "aws_kms_key_detail" {

  title         = "AWS KMS Key Detail"
  documentation = file("./dashboards/kms/docs/kms_key_detail.md")

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })


  input "key_arn" {
    title = "Select a key:"
    query = query.aws_kms_key_input
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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_kms_key_nodes,
        node.aws_kms_key_to_kms_alias_node,
        node.aws_kms_key_from_cloudtrail_trail_node,
        node.aws_kms_key_from_ebs_volume_node,
        node.aws_kms_key_from_rds_db_cluster_snapshot_node,
        node.aws_kms_key_from_rds_db_cluster_node,
        node.aws_kms_key_from_rds_db_instance_node,
        node.aws_kms_key_from_rds_db_snapshot_node,
        node.aws_kms_key_from_redshift_cluster_node,
        node.aws_kms_key_from_sns_topic_node,
        node.aws_kms_key_from_sqs_queue_node,
        node.aws_kms_key_from_lambda_function_node,
        node.aws_kms_key_from_s3_bucket_node
      ]

      edges = [
        edge.aws_kms_key_to_kms_alias_edge,
        edge.aws_kms_key_from_cloudtrail_trail_edge,
        edge.aws_kms_key_from_ebs_volume_edge,
        edge.aws_kms_key_from_rds_db_cluster_snapshot_edge,
        edge.aws_kms_key_from_rds_db_cluster_edge,
        edge.aws_kms_key_from_rds_db_instance_edge,
        edge.aws_kms_key_from_rds_db_snapshot_edge,
        edge.aws_kms_key_from_redshift_cluster_edge,
        edge.aws_kms_key_from_sns_topic_edge,
        edge.aws_kms_key_from_sqs_queue_edge,
        edge.aws_kms_key_from_lambda_function_edge,
        edge.aws_kms_key_from_s3_bucket_edge
      ]

      args = {
        kms_key_arns = [self.input.key_arn.value]
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
      coalesce(a.title, k.title) as label,
      k.arn as value,
      json_build_object(
        'target_key_id', a.target_key_id,
        'account_id', k.account_id,
        'region', k.region
      ) as tags
    from
      aws_kms_key as k
      left join aws_kms_alias as a
      on a.target_key_id = k.id
    order by
      a.title;
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

node "aws_kms_key_nodes" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      arn as id,
      left(id,8) as title,
      jsonb_build_object(
        'ARN', arn,
        'Key Manager', key_manager,
        'Creation Date', creation_date,
        'Enabled', enabled::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_kms_key
    where
      arn = any($1);
  EOQ

  param "kms_key_arns" {}
}

node "aws_kms_key_from_cloudtrail_trail_node" {
  category = category.aws_cloudtrail_trail

  sql = <<-EOQ
    select
      t.arn as id,
      t.name as title,
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
      t.kms_key_id = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_cloudtrail_trail_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      t.arn as from_id,
      k.arn as to_id
    from
      aws_cloudtrail_trail as t,
      aws_kms_key as k
    where
      t.kms_key_id = $1;
  EOQ

  param "arn" {}
}

node "aws_kms_key_from_ebs_volume_node" {
  category = category.aws_ebs_volume

  sql = <<-EOQ
    select
      volume_id as id,
      volume_id as title,
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
      v.kms_key_id = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_ebs_volume_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      volume_id as from_id,
      k.arn as to_id
    from
      aws_ebs_volume as v,
      aws_kms_key as k
    where
      v.kms_key_id = $1;
  EOQ

  param "arn" {}
}

node "aws_kms_key_from_rds_db_cluster_snapshot_node" {
  category = category.aws_rds_db_cluster_snapshot

  sql = <<-EOQ
    select
      db_cluster_snapshot_identifier as id,
      db_cluster_snapshot_identifier as title,
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
      s.kms_key_id = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_rds_db_cluster_snapshot_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      db_cluster_snapshot_identifier as from_id,
      k.arn as to_id
    from
      aws_rds_db_cluster_snapshot as s,
      aws_kms_key as k
    where
      s.kms_key_id = $1;
  EOQ

  param "arn" {}
}

node "aws_kms_key_from_rds_db_cluster_node" {
  category = category.aws_rds_db_cluster

  sql = <<-EOQ
    select
      db_cluster_identifier as id,
      db_cluster_identifier as title,
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
      c.kms_key_id = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_rds_db_cluster_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      db_cluster_identifier as from_id,
      k.arn as to_id
    from
      aws_rds_db_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = $1;
  EOQ

  param "arn" {}
}

node "aws_kms_key_from_rds_db_instance_node" {
  category = category.aws_rds_db_instance

  sql = <<-EOQ
    select
      db_instance_identifier as id,
      db_instance_identifier as title,
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
      i.kms_key_id = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_rds_db_instance_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      db_instance_identifier as from_id,
      k.arn as to_id
    from
      aws_rds_db_instance as i,
      aws_kms_key as k
    where
      i.kms_key_id = $1;
  EOQ

  param "arn" {}
}

node "aws_kms_key_from_rds_db_snapshot_node" {
  category = category.aws_rds_db_snapshot

  sql = <<-EOQ
    select
      db_snapshot_identifier as id,
      db_snapshot_identifier as title,
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
      s.kms_key_id = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_rds_db_snapshot_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      db_snapshot_identifier as from_id,
      k.arn as to_id
    from
      aws_rds_db_snapshot as s,
      aws_kms_key as k
    where
      s.kms_key_id = $1;
  EOQ

  param "arn" {}
}

node "aws_kms_key_from_redshift_cluster_node" {
  category = category.aws_redshift_cluster

  sql = <<-EOQ
    select
      cluster_identifier as id,
      cluster_identifier as title,
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
      c.kms_key_id = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_redshift_cluster_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      cluster_identifier as from_id,
      k.arn as to_id
    from
      aws_redshift_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = $1;
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


node "aws_kms_key_from_sns_topic_node" {
  category = category.aws_sns_topic

  sql = <<-EOQ
    select
      t.topic_arn as id,
      t.title as title,
      jsonb_build_object(
        'ARN', t.topic_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_sns_topic as t
      left join aws_kms_key as k on k.arn = split_part(t.kms_master_key_id, '/', 2)
    where
      k.arn = $1
      and k.region = t.region
      and k.account_id = t.account_id;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_sns_topic_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      t.topic_arn as from_id,
      k.arn as to_id
    from
      aws_sns_topic as t
      left join aws_kms_key as k on k.id = split_part(t.kms_master_key_id, '/', 2)
    where
      k.arn = $1
      and k.region = t.region
      and k.account_id = t.account_id;
  EOQ

  param "arn" {}
}


node "aws_kms_key_from_sqs_queue_node" {
  category = category.aws_sqs_queue

  sql = <<-EOQ
    select
      q.queue_arn as id,
      q.title as title,
      jsonb_build_object(
        'ARN', q.queue_arn,
        'Account ID', q.account_id,
        'Region', q.region
      ) as properties
    from
      aws_kms_key as k
      join aws_kms_alias as a
      on a.target_key_id = k.id
      join aws_sqs_queue as q
      on a.alias_name = q.kms_master_key_id
      and k.region = q.region
      and k.account_id = q.account_id
    where
      k.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_sqs_queue_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      q.queue_arn as from_id,
      a.arn as to_id
    from
       aws_kms_key as k
      join aws_kms_alias as a
      on a.target_key_id = k.id
      join aws_sqs_queue as q
      on a.alias_name = q.kms_master_key_id
      and k.region = q.region
      and k.account_id = q.account_id
    where
      k.arn = $1;
  EOQ

  param "arn" {}
}


node "aws_kms_key_from_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      l.arn as id,
      l.title as title,
      jsonb_build_object(
        'ARN', l.arn,
        'Runtime', l.runtime,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      aws_lambda_function as l,
      aws_kms_key as k
    where
      k.arn = l.kms_key_arn
      and k.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_lambda_function_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      l.arn as from_id,
      k.arn as to_id
    from
      aws_lambda_function as l,
      aws_kms_key as k
    where
      k.arn = l.kms_key_arn
      and k.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_kms_key_from_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      b.arn as id,
      b.title as title,
      jsonb_build_object(
        'Name', b.name,
        'ARN', b.arn,
        'Account ID', b.account_id,
        'Region', b.region
      ) as properties
    from
      aws_s3_bucket as b
      cross join jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as r
      join aws_kms_key as k
      on k.arn = r -> 'ApplyServerSideEncryptionByDefault' ->> 'KMSMasterKeyID'
    where
      k.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_from_s3_bucket_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      b.arn as from_id,
      k.arn as to_id
    from
      aws_s3_bucket as b
      cross join jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as r
      join aws_kms_key as k
      on k.arn = r -> 'ApplyServerSideEncryptionByDefault' ->> 'KMSMasterKeyID'
    where
      k.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_kms_key_to_kms_alias_node" {
  category = category.aws_kms_alias

  sql = <<-EOQ
    select
      a.arn as id,
      a.title as title,
      jsonb_build_object(
        'ARN', a.arn,
        'Create Date', a.creation_date,
        'Account ID', a.account_id,
        'Region', a.region
      ) as properties
    from
      aws_kms_alias as a
      join aws_kms_key as k
      on a.target_key_id = k.id
    where
      k.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_kms_key_to_kms_alias_edge" {
  title = "key"

  sql = <<-EOQ
    select
      a.arn as from_id,
      k.arn as to_id
    from
      aws_kms_alias as a
      join aws_kms_key as k
      on a.target_key_id = k.id
    where
      k.arn = $1;
  EOQ

  param "arn" {}
}
