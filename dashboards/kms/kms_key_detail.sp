dashboard "kms_key_detail" {

  title         = "AWS KMS Key Detail"
  documentation = file("./dashboards/kms/docs/kms_key_detail.md")

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })


  input "key_arn" {
    title = "Select a key:"
    query = query.kms_key_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.kms_key_type
      args = [self.input.key_arn.value]
    }

    card {
      width = 2
      query = query.kms_key_origin
      args = [self.input.key_arn.value]
    }

    card {
      width = 2
      query = query.kms_key_state
      args = [self.input.key_arn.value]
    }

    card {
      width = 2
      query = query.kms_key_rotation_enabled
      args = [self.input.key_arn.value]
    }

  }

  with "cloudtrail_trails" {
    query = query.kms_key_cloudtrail_trails
    args = [self.input.key_arn.value]
  }

  with "ebs_volumes" {
    query = query.kms_key_ebs_volumes
    args = [self.input.key_arn.value]
  }

  with "lambda_functions" {
    query = query.kms_key_lambda_functions
    args = [self.input.key_arn.value]
  }

  with "rds_db_clusters" {
    query = query.kms_key_rds_db_clusters
    args = [self.input.key_arn.value]
  }

  with "rds_db_cluster_snapshots" {
    query = query.kms_key_rds_db_cluster_snapshots
    args = [self.input.key_arn.value]
  }

  with "rds_db_instances" {
    query = query.kms_key_rds_db_instances
    args = [self.input.key_arn.value]
  }

  with "rds_db_snapshots" {
    query = query.kms_key_rds_db_snapshots
    args = [self.input.key_arn.value]

  }

  with "redshift_clusters" {
    query = query.kms_key_redshift_clusters
    args = [self.input.key_arn.value]
  }

  with "s3_buckets" {
    query = query.kms_key_s3_buckets
    args = [self.input.key_arn.value]

  }

  with "sns_topics" {
    query = query.kms_key_sns_topics
    args = [self.input.key_arn.value]
  }

  with "sqs_queues" {
    query = query.kms_key_sqs_queues
    args = [self.input.key_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.cloudtrail_trail
        args = {
          cloudtrail_trail_arns = with.cloudtrail_trails.rows[*].trail_arn
        }
      }

      node {
        base = node.ebs_volume
        args = {
          ebs_volume_arns = with.ebs_volumes.rows[*].volume_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = [self.input.key_arn.value]
        }
      }

      node {
        base = node.kms_key_alias
        args = {
          kms_key_arns = [self.input.key_arn.value]
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions.rows[*].function_arn
        }
      }

      node {
        base = node.rds_db_cluster
        args = {
          rds_db_cluster_arns = with.rds_db_clusters.rows[*].cluster_arn
        }
      }

      node {
        base = node.rds_db_cluster_snapshot
        args = {
          rds_db_cluster_snapshot_arns = with.rds_db_cluster_snapshots.rows[*].cluster_snapshot_arn
        }
      }

      node {
        base = node.rds_db_instance
        args = {
          rds_db_instance_arns = with.rds_db_instances.rows[*].db_instance_arn
        }
      }

      node {
        base = node.rds_db_snapshot
        args = {
          rds_db_snapshot_arns = with.rds_db_snapshots.rows[*].db_snapshot_arn
        }
      }

      node {
        base = node.redshift_cluster
        args = {
          redshift_cluster_arns = with.redshift_clusters.rows[*].redshift_cluster_arn
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.s3_buckets.rows[*].bucket_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics.rows[*].topic_arn
        }
      }

      node {
        base = node.sqs_queue
        args = {
          sqs_queue_arns = with.sqs_queues.rows[*].queue_arn
        }
      }

      edge {
        base = edge.cloudtrail_trail_to_kms_key
        args = {
          cloudtrail_trail_arns = with.cloudtrail_trails.rows[*].trail_arn
        }
      }

      edge {
        base = edge.ebs_volume_to_kms_key
        args = {
          ebs_volume_arns = with.ebs_volumes.rows[*].volume_arn
        }
      }

      edge {
        base = edge.kms_key_to_kms_alias
        args = {
          kms_key_arns = [self.input.key_arn.value]
        }
      }

      edge {
        base = edge.lambda_function_to_kms_key
        args = {
          lambda_function_arns = with.lambda_functions.rows[*].function_arn
        }
      }

      edge {
        base = edge.rds_db_cluster_snapshot_to_kms_key
        args = {
          rds_db_cluster_snapshot_arns = with.rds_db_cluster_snapshots.rows[*].cluster_snapshot_arn
        }
      }

      edge {
        base = edge.rds_db_cluster_to_kms_key
        args = {
          rds_db_cluster_arns = with.rds_db_clusters.rows[*].cluster_arn
        }
      }

      edge {
        base = edge.rds_db_instance_to_kms_key
        args = {
          rds_db_instance_arns = with.rds_db_instances.rows[*].db_instance_arn
        }
      }

      edge {
        base = edge.rds_db_snapshot_to_kms_key
        args = {
          rds_db_snapshot_arns = with.rds_db_snapshots.rows[*].db_snapshot_arn
        }
      }

      edge {
        base = edge.redshift_cluster_to_kms_key
        args = {
          redshift_cluster_arns = with.redshift_clusters.rows[*].redshift_cluster_arn
        }
      }

      edge {
        base = edge.s3_bucket_to_kms_key
        args = {
          s3_bucket_arns = with.s3_buckets.rows[*].bucket_arn
        }
      }

      edge {
        base = edge.sns_topic_to_kms_key
        args = {
          sns_topic_arns = with.sns_topics.rows[*].topic_arn
        }
      }

      edge {
        base = edge.sqs_queue_to_kms_key_alias
        args = {
          sqs_queue_arns = with.sqs_queues.rows[*].queue_arn
        }
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
        query = query.kms_key_overview
        args = [self.input.key_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.kms_key_tags
        args = [self.input.key_arn.value]
      }

    }

    container {

      width = 6

      table {
        title = "Key Age"
        query = query.kms_key_age
        args = [self.input.key_arn.value]
      }

    }

  }

  table {
    title = "Policy"
    query = query.kms_key_policy
    args = [self.input.key_arn.value]
  }

  table {
    title = "Key Aliases"
    query = query.kms_key_aliases
    args = [self.input.key_arn.value]
  }

}

# Input queries

query "kms_key_input" {
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

# With queries

query "kms_key_cloudtrail_trails" {
  sql = <<-EOQ
    select
      t.arn as trail_arn
    from
      aws_cloudtrail_trail as t
    where
      t.kms_key_id = $1;
  EOQ
}

query "kms_key_ebs_volumes" {
  sql = <<-EOQ
    select
      v.arn as volume_arn
    from
      aws_ebs_volume as v
    where
      v.kms_key_id = $1;
  EOQ
}

query "kms_key_lambda_functions" {
  sql = <<-EOQ
    select
      arn as function_arn
    from
      aws_lambda_function
    where
      kms_key_arn = $1;
  EOQ
}

query "kms_key_rds_db_clusters" {
  sql = <<-EOQ
    select
      arn as cluster_arn
    from
      aws_rds_db_cluster as c
    where
      c.kms_key_id = $1;
  EOQ
}

query "kms_key_rds_db_cluster_snapshots" {
  sql = <<-EOQ
    select
      s.arn as cluster_snapshot_arn
    from
      aws_rds_db_cluster_snapshot as s
    where
      s.kms_key_id = $1;
  EOQ
}

query "kms_key_rds_db_instances" {
  sql = <<-EOQ
    select
      arn as db_instance_arn
    from
      aws_rds_db_instance as i
    where
      i.kms_key_id = $1;
  EOQ
}

query "kms_key_rds_db_snapshots" {
  sql = <<-EOQ
    select
      arn as db_snapshot_arn
    from
      aws_rds_db_snapshot as s
    where
      s.kms_key_id = $1;
  EOQ
}

query "kms_key_redshift_clusters" {
  sql = <<-EOQ
    select
      arn as redshift_cluster_arn
    from
      aws_redshift_cluster as c
    where
      c.kms_key_id = $1;
  EOQ
}

query "kms_key_s3_buckets" {
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
}

query "kms_key_sns_topics" {
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
}

query "kms_key_sqs_queues" {
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
}

# Card queries

query "kms_key_type" {
  sql = <<-EOQ
    select
      'Key Manager' as label,
      key_manager as value
    from
      aws_kms_key
    where
      arn = $1;
  EOQ
}

query "kms_key_origin" {
  sql = <<-EOQ
    select
      'Origin' as label,
      origin as value
    from
      aws_kms_key
    where
      arn = $1;
  EOQ
}

query "kms_key_state" {
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
}

query "kms_key_rotation_enabled" {
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
}

# Other detail page queries

query "kms_key_overview" {
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
}

query "kms_key_tags" {
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
}

query "kms_key_age" {
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
}

query "kms_key_aliases" {
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
}

query "kms_key_policy" {
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
}
