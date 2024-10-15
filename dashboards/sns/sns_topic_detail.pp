dashboard "sns_topic_detail" {

  title         = "AWS SNS Topic Detail"
  documentation = file("./dashboards/sns/docs/sns_topic_detail.md")

  tags = merge(local.sns_common_tags, {
    type = "Detail"
  })

  input "topic_arn" {
    title = "Select a topic:"
    query = query.sns_topic_input
    width = 4
  }

  container {

    card {
      width = 3
      query = query.sns_topic_encryption_status
      args  = [self.input.topic_arn.value]
    }

    card {
      query = query.sns_topic_subscriptions_confirmed_count
      width = 3
      args  = [self.input.topic_arn.value]
    }
  }

  with "cloudformation_stacks_for_sns_topic" {
    query = query.cloudformation_stacks_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  with "cloudtrail_trails_for_sns_topic" {
    query = query.cloudtrail_trails_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  with "elasticache_clusters_for_sns_topic" {
    query = query.elasticache_clusters_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  with "kms_keys_for_sns_topic" {
    query = query.kms_keys_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  with "rds_db_instances_for_sns_topic" {
    query = query.rds_db_instances_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  with "redshift_clusters_for_sns_topic" {
    query = query.redshift_clusters_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  with "s3_buckets_for_sns_topic" {
    query = query.s3_buckets_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  with "sns_topic_subscriptions_for_sns_topic" {
    query = query.sns_topic_subscriptions_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  with "topic_policy_std_for_sns_topic" {
    query = query.topic_policy_std_for_sns_topic
    args  = [self.input.topic_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      node {
        base = node.cloudformation_stack
        args = {
          cloudformation_stack_ids = with.cloudformation_stacks_for_sns_topic.rows[*].stack_id
        }
      }

      node {
        base = node.cloudtrail_trail
        args = {
          cloudtrail_trail_arns = with.cloudtrail_trails_for_sns_topic.rows[*].trail_arn
        }
      }

      node {
        base = node.elasticache_cluster_node
        args = {
          elasticache_cluster_node_arns = with.elasticache_clusters_for_sns_topic.rows[*].elasticache_cluster_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_sns_topic.rows[*].key_arn
        }
      }

      node {
        base = node.rds_db_instance
        args = {
          rds_db_instance_arns = with.rds_db_instances_for_sns_topic.rows[*].db_instance_arn
        }
      }

      node {
        base = node.redshift_cluster
        args = {
          redshift_cluster_arns = with.redshift_clusters_for_sns_topic.rows[*].cluster_arn
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.s3_buckets_for_sns_topic.rows[*].bucket_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = [self.input.topic_arn.value]
        }
      }

      node {
        base = node.sns_topic_subscription
        args = {
          sns_topic_subscription_arns = with.sns_topic_subscriptions_for_sns_topic.rows[*].subscription_arn
        }
      }

      edge {
        base = edge.cloudformation_stack_to_sns_topic
        args = {
          sns_topic_arns = [self.input.topic_arn.value]
        }
      }

      edge {
        base = edge.cloudtrail_trail_to_sns_topic
        args = {
          cloudtrail_trail_arns = with.cloudtrail_trails_for_sns_topic.rows[*].trail_arn
        }
      }

      edge {
        base = edge.elasticache_cluster_node_to_sns_topic
        args = {
          elasticache_cluster_node_arns = with.elasticache_clusters_for_sns_topic.rows[*].elasticache_cluster_arn
        }
      }

      edge {
        base = edge.rds_db_instance_to_sns_topic
        args = {
          rds_db_instance_arns = with.rds_db_instances_for_sns_topic.rows[*].db_instance_arn
        }
      }

      edge {
        base = edge.redshift_cluster_to_sns_topic
        args = {
          redshift_cluster_arns = with.redshift_clusters_for_sns_topic.rows[*].cluster_arn
        }
      }

      edge {
        base = edge.s3_bucket_to_sns_topic
        args = {
          s3_bucket_arns = with.s3_buckets_for_sns_topic.rows[*].bucket_arn
        }
      }

      edge {
        base = edge.sns_topic_to_kms_key
        args = {
          sns_topic_arns = [self.input.topic_arn.value]
        }
      }

      edge {
        base = edge.sns_topic_to_sns_subscription
        args = {
          sns_topic_arns = [self.input.topic_arn.value]
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
        query = query.sns_topic_overview
        args  = [self.input.topic_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.sns_topic_tags
        args  = [self.input.topic_arn.value]

      }
    }

    container {
      width = 6

      table {
        title = "Subscription Counts"
        query = query.sns_topic_subscription_count
        args  = [self.input.topic_arn.value]
      }

    }

    container {
      width = 12

      table {
        title = "Effective Delivery Policy"
        query = query.sns_topic_delivery_policy
        args  = [self.input.topic_arn.value]
      }
    }

    graph {
      title = "Resource Policy"
      base  = graph.iam_resource_policy_structure
      args = {
        policy_std = with.topic_policy_std_for_sns_topic.rows[0].policy_std
      }
    }

  }
}

query "sns_topic_input" {
  sql = <<-EOQ
    select
      topic_arn as label,
      topic_arn as value
    from
      aws_sns_topic
    order by
      topic_arn;
EOQ
}

# card queries

query "sns_topic_encryption_status" {
  sql = <<-EOQ
    select
      case when kms_master_key_id is not null then 'Enabled' else 'Disabled' end as value,
      'Encryption' as label,
      case when kms_master_key_id is not null then 'ok' else 'alert' end as "type"
    from
      aws_sns_topic
    where
      topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "sns_topic_subscriptions_confirmed_count" {
  sql = <<-EOQ
    select
      subscriptions_confirmed::int as value,
      'Confirmed Subscriptions' as label,
      case when subscriptions_confirmed::int = 0 then 'alert' else 'ok' end as "type"
    from
      aws_sns_topic
    where
      topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

# with queries
query "cloudformation_stacks_for_sns_topic" {
  sql = <<-EOQ
    select
      s.id as stack_id
    from
      aws_sns_topic as t,
      aws_cloudformation_stack as s,
      jsonb_array_elements(
        case jsonb_typeof(notification_arns)
          when 'array' then (notification_arns)
          else null end
      ) n
    where
      t.topic_arn = trim((n::text ), '""')
      and t.topic_arn = $1
      and t.account_id = split_part($1, ':', 5)
      and t.region = split_part($1, ':', 4);
  EOQ
}

query "cloudtrail_trails_for_sns_topic" {
  sql = <<-EOQ
    select
      arn as trail_arn
    from
      aws_cloudtrail_trail
    where
      sns_topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_clusters_for_sns_topic" {
  sql = <<-EOQ
    select
      arn as elasticache_cluster_arn
    from
      aws_elasticache_cluster
    where
      notification_configuration ->> 'TopicArn' = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "kms_keys_for_sns_topic" {
  sql = <<-EOQ
    select
      kms_master_key_id as key_arn
    from
      aws_sns_topic
    where
      kms_master_key_id is not null
      and topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "topic_policy_std_for_sns_topic" {
  sql = <<-EOQ
    select
      policy_std
    from
      aws_sns_topic
    where
      topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "rds_db_instances_for_sns_topic" {
  sql = <<-EOQ
    with rds_event_subscriptions as (
      select
        source_ids_list,
        sns_topic_arn
      from
        aws_rds_db_event_subscription
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    )
    select
      i.arn as db_instance_arn
    from
      rds_event_subscriptions as s,
      jsonb_array_elements_text(source_ids_list) as ids
      join aws_rds_db_instance as i
      on ids = i.db_instance_identifier
    where
      s.sns_topic_arn = $1
      and i.account_id = split_part($1, ':', 5)
      and i.region = split_part($1, ':', 4);
  EOQ
}

query "redshift_clusters_for_sns_topic" {
  sql = <<-EOQ
    with redshift_event_subscriptions as (
      select
        source_ids_list,
        sns_topic_arn
      from
        aws_redshift_event_subscription
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    )
    select
      c.arn as cluster_arn
    from
      redshift_event_subscriptions as s,
      jsonb_array_elements_text(source_ids_list) as ids
      join aws_redshift_cluster as c
      on ids = c.cluster_identifier
    where
      s.sns_topic_arn = $1
      and c.account_id = split_part($1, ':', 5)
      and c.region = split_part($1, ':', 4);
  EOQ
}

query "s3_buckets_for_sns_topic" {
  sql = <<-EOQ
    select
      b.arn as bucket_arn
    from
      aws_s3_bucket as b,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'TopicConfigurations')
          when 'array' then (event_notification_configuration -> 'TopicConfigurations')
          else null end
        )
        as t
    where
      t ->> 'TopicArn' = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "sns_topic_subscriptions_for_sns_topic" {
  sql = <<-EOQ
    select
      subscription_arn as subscription_arn
    from
      aws_sns_topic_subscription
    where
      topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

# table queries

query "sns_topic_overview" {
  sql = <<-EOQ
    select
      display_name as "Display Name",
      owner as "Owner",
      kms_master_key_id as "KMS Key ID",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      topic_arn as "ARN"
    from
      aws_sns_topic
    where
      topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "sns_topic_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_sns_topic,
      jsonb_array_elements(tags_src) as tag
    where
      topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
    order by
      tag ->> 'Key';
  EOQ

}

query "sns_topic_subscription_count" {
  sql = <<-EOQ
    select
      subscriptions_confirmed as "Confirmed",
      subscriptions_deleted as "Deleted",
      subscriptions_pending as "Pending"
    from
      aws_sns_topic
    where
      topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "sns_topic_delivery_policy" {
  sql = <<-EOQ
    select
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'numRetries' as "Retries",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'maxDelayTarget' as "Maximum Delay Target",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'minDelayTarget' as "Minimum Delay Target",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'backoffFunction' as "Backoff Function",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'numNoDelayRetries' as "No Delay Retries",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'numMaxDelayRetries' as "Maximum Delay Retries",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'numMinDelayRetries' as "Minimum Delay Retries",
      (effective_delivery_policy -> 'http' -> 'disableSubscriptionOverrides')::boolean as "Disable Subscription Overrides"
    from
      aws_sns_topic
    where
      topic_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

