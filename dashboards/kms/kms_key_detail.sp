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

      with "trails" {
        sql = <<-EOQ
          select
            t.arn as trail_arn
          from
            aws_cloudtrail_trail as t
          where
            t.kms_key_id = $1;
        EOQ

        args = [self.input.key_arn.value]
      }

      with "volumes" {
        sql = <<-EOQ
          select
            v.arn as volume_arn
          from
            aws_ebs_volume as v
          where
            v.kms_key_id = $1;
        EOQ

        args = [self.input.key_arn.value]
      }

      with "rds_db_cluster_snapshots" {
        sql = <<-EOQ
          select
            s.arn as cluster_snapshot_arn
          from
            aws_rds_db_cluster_snapshot as s
          where
            s.kms_key_id = $1;
        EOQ

        args = [self.input.key_arn.value]
      }

      with "rds_db_clusters" {
        sql = <<-EOQ
          select
            arn as cluster_arn
          from
            aws_rds_db_cluster as c
          where
            c.kms_key_id = $1;
        EOQ

        args = [self.input.key_arn.value]
      }

      with "rds_db_instances" {
        sql = <<-EOQ
          select
            arn as db_instance_arn
          from
            aws_rds_db_instance as i
          where
            i.kms_key_id = $1;
        EOQ

        args = [self.input.key_arn.value]
      }

      with "redshift_clusters" {
        sql = <<-EOQ
          select
            arn as redshift_cluster_arn
          from
            aws_redshift_cluster as c
          where
            c.kms_key_id = $1;
        EOQ

        args = [self.input.key_arn.value]
      }

      with "topics" {
        sql = <<-EOQ
          select
            t.topic_arn as topic_arn
          from
            aws_sns_topic as t
            left join aws_kms_key as k on k.id = split_part(t.kms_master_key_id, '/', 2)
          where
            k.arn = $1
            and k.region = t.region
            and k.account_id = t.account_id;
        EOQ

        args = [self.input.key_arn.value]
      }

      with "queues" {
        sql = <<-EOQ
          select
            q.queue_arn as queue_arn
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

        args = [self.input.key_arn.value]
      }

      with "functions" {
        sql = <<-EOQ
          select
            l.arn as function_arn
          from
            aws_lambda_function as l,
            aws_kms_key as k
          where
            k.arn = l.kms_key_arn
            and k.arn = $1;
        EOQ

        args = [self.input.key_arn.value]
      }

      with "rds_db_snapshots" {
        sql = <<-EOQ
          select
            arn as db_snapshot_arn
          from
            aws_rds_db_snapshot as s
          where
            s.kms_key_id = $1;
        EOQ

        args = [self.input.key_arn.value]

      }

      with "buckets" {
        sql = <<-EOQ
          select
            b.arn as bucket_arn
          from
            aws_s3_bucket as b
            cross join jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as r
            join aws_kms_key as k
            on k.arn = r -> 'ApplyServerSideEncryptionByDefault' ->> 'KMSMasterKeyID'
          where
            k.arn = $1;
        EOQ

        args = [self.input.key_arn.value]

      }

      nodes = [
        node.aws_kms_key_nodes,
        node.aws_kms_key_alias_nodes,
        node.aws_cloudtrail_trail_nodes,
        node.aws_ebs_volume_nodes,
        node.aws_rds_db_cluster_snapshot_nodes,
        node.aws_rds_db_cluster_nodes,
        node.aws_redshift_cluster_nodes,
        node.aws_sns_topic_nodes,
        node.aws_sqs_queue_nodes,
        node.aws_rds_db_instance_nodes,
        node.aws_rds_db_snapshot_nodes,
        node.aws_lambda_function_nodes,
        node.aws_s3_bucket_nodes
      ]

      edges = [
        edge.aws_kms_key_to_kms_alias_edge,
        edge.aws_kms_key_from_cloudtrail_trail_edges,
        edge.aws_kms_key_from_ebs_volume_edges,
        edge.aws_rds_db_cluster_snapshot_to_kms_key_edges,
        edge.aws_kms_key_from_rds_db_cluster_edges,
        edge.aws_kms_key_from_redshift_cluster_edges,
        edge.aws_kms_key_from_sns_topic_edges,
        edge.aws_kms_key_from_sqs_queue_edges,
        edge.aws_rds_db_instance_to_kms_key_edge,
        edge.aws_rds_db_snapshot_to_kms_key_edges,
        edge.aws_kms_key_from_lambda_function_edges,
        edge.aws_s3_bucket_to_kms_key_edges
      ]

      args = {
        key_arns                     = [self.input.key_arn.value]
        trail_arns                   = with.trails.rows[*].trail_arn
        volume_arns                  = with.volumes.rows[*].volume_arn
        rds_db_cluster_snapshot_arns = with.rds_db_cluster_snapshots.rows[*].cluster_snapshot_arn
        rds_db_cluster_arns          = with.rds_db_clusters.rows[*].cluster_arn
        rds_db_instance_arns         = with.rds_db_instances.rows[*].db_instance_arn
        rds_db_snapshot_arns         = with.rds_db_snapshots.rows[*].db_snapshot_arn
        redshift_cluster_arns        = with.redshift_clusters.rows[*].redshift_cluster_arn
        topic_arns                   = with.topics.rows[*].topic_arn
        queue_arns                   = with.queues.rows[*].queue_arn
        function_arns                = with.functions.rows[*].function_arn
        bucket_arns                  = with.buckets.rows[*].bucket_arn
        arn                          = self.input.key_arn.value
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

  param "key_arns" {}
}

edge "aws_kms_key_from_cloudtrail_trail_edges" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      trail_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as key_arn,
      unnest($2::text[]) as trail_arn
  EOQ

  param "key_arns" {}
  param "trail_arns" {}
}

edge "aws_kms_key_from_ebs_volume_edges" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      volume_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as key_arn,
      unnest($2::text[]) as volume_arn
  EOQ

  param "key_arns" {}
  param "volume_arns" {}
}

edge "aws_kms_key_from_rds_db_cluster_edges" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      rds_cluster_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as key_arn,
      unnest($2::text[]) as rds_cluster_arn
  EOQ

  param "key_arns" {}
  param "rds_db_cluster_arns" {}
}

edge "aws_kms_key_from_redshift_cluster_edges" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      redshift_cluster_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as key_arn,
      unnest($2::text[]) as redshift_cluster_arn
  EOQ

  param "key_arns" {}
  param "redshift_cluster_arns" {}
}

edge "aws_kms_key_from_sns_topic_edges" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      topic_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as key_arn,
      unnest($2::text[]) as topic_arn
  EOQ

  param "key_arns" {}
  param "topic_arns" {}
}

edge "aws_kms_key_from_sqs_queue_edges" {
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
      k.arn = any($1);
  EOQ

  param "key_arns" {}
}

edge "aws_kms_key_from_lambda_function_edges" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      function_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as key_arn,
      unnest($2::text[]) as function_arn
  EOQ

  param "key_arns" {}
  param "function_arns" {}
}

node "aws_kms_key_alias_nodes" {
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
      k.arn = any($1);
  EOQ

  param "key_arns" {}
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
      k.arn = any($1);
  EOQ

  param "key_arns" {}
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
