dashboard "aws_sns_topic_detail" {

  title         = "AWS SNS Topic Detail"
  documentation = file("./dashboards/sns/docs/sns_topic_detail.md")

  tags = merge(local.sns_common_tags, {
    type = "Detail"
  })

  input "topic_arn" {
    title = "Select a topic:"
    sql   = query.aws_sns_topic_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_sns_topic_encryption_status
      args = {
        arn = self.input.topic_arn.value
      }
    }

    card {
      query = query.aws_sns_topic_subscriptions_confirmed_count
      width = 2
      args = {
        arn = self.input.topic_arn.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_sns_topic_node,
        node.aws_sns_topic_to_kms_key_node,
        node.aws_sns_topic_to_sns_topic_subscriptions_node,
        node.aws_sns_topic_from_s3_bucket_node,
        node.aws_sns_topic_from_rds_db_instance_node,
        node.aws_sns_topic_from_redshift_cluster_node,
        node.aws_sns_topic_from_cloudtrail_trail_node,
        node.aws_sns_topic_from_cloudformation_stack_node,
        node.aws_sns_topic_from_aws_elasticache_cluster_node
      ]

      edges = [
        edge.aws_sns_topic_to_kms_key_edge,
        edge.aws_sns_topic_to_sns_topic_subscriptions_edge,
        edge.aws_sns_topic_from_s3_bucket_edge,
        edge.aws_sns_topic_from_rds_db_instance_edge,
        edge.aws_sns_topic_from_redshift_cluster_edge,
        edge.aws_sns_topic_from_cloudtrail_trail_edge,
        edge.aws_sns_topic_from_cloudformation_stack_edge,
        edge.aws_sns_topic_from_aws_elasticache_cluster_edge
      ]

      args = {
        arn = self.input.topic_arn.value
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
        query = query.aws_sns_topic_overview
        args = {
          arn = self.input.topic_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_sns_topic_tags
        args = {
          arn = self.input.topic_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Subscription Counts"
        query = query.aws_sns_topic_subscriptions
        args = {
          arn = self.input.topic_arn.value
        }
      }

    }

    container {
      width = 12

      table {
        title = "Effective Delivery Policy"
        query = query.aws_sns_topic_delivery_policy
        args = {
          arn = self.input.topic_arn.value
        }
      }

      table {
        title = "Policy"
        query = query.aws_sns_topic_policy_standard
        args = {
          arn = self.input.topic_arn.value
        }
      }
    }

  }
}

query "aws_sns_topic_input" {
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

query "aws_sns_topic_encryption_status" {
  sql = <<-EOQ
    select
      case when kms_master_key_id is not null then 'Enabled' else 'Disabled' end as value,
      'Encryption' as label,
      case when kms_master_key_id is not null then 'ok' else 'alert' end as "type"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_subscriptions_confirmed_count" {
  sql = <<-EOQ
    select
      subscriptions_confirmed::int as value,
      'Confirmed Subscriptions' as label,
      case when subscriptions_confirmed::int = 0 then 'alert' else 'ok' end as "type"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_overview" {
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
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_sns_topic,
      jsonb_array_elements(tags_src) as tag
    where
      topic_arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_sns_topic_subscriptions" {
  sql = <<-EOQ
    select
      subscriptions_confirmed as "Confirmed",
      subscriptions_deleted as "Deleted",
      subscriptions_pending as "Pending"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_delivery_policy" {
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
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_policy_standard" {
  sql = <<-EOQ
    select
      statement ->> 'Sid' as "SID",
      statement ->> 'Effect' as "Effect",
      statement ->> 'Principal' as "Principal",
      statement ->> 'Action' as "Action",
      statement ->> 'Resource' as "Resource",
      statement ->> 'Condition' as "Condition"
    from
      aws_sns_topic as t,
      jsonb_array_elements(policy_std -> 'Statement') as statement
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_node" {
  category = category.aws_sns_topic

  sql = <<-EOQ
    select
      topic_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', topic_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sns_topic as q
    where
      q.topic_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      k.arn as id,
      k.title as title,
      jsonb_build_object(
        'ARN', k.arn,
        'ID', k.id,
        'enabled', k.enabled,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_sns_topic as q
      left join aws_kms_key as k on k.id = split_part(q.kms_master_key_id, '/', 2)
    where
      q.topic_arn = $1
      and k.region = q.region;
  EOQ

  param "arn" {}
}

edge "aws_sns_topic_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      q.topic_arn as from_id,
      k.arn as to_id
    from
      aws_sns_topic as q
      left join aws_kms_key as k on k.id = split_part(q.kms_master_key_id, '/', 2)
    where
      q.topic_arn = $1
      and k.region = q.region;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_to_sns_topic_subscriptions_node" {
  category = category.aws_sns_topic_subscription

  sql = <<-EOQ
    select
      subscription_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Pending Confirmation', pending_confirmation,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sns_topic_subscription
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_sns_topic_to_sns_topic_subscriptions_edge" {
  title = "subscribe to"

  sql = <<-EOQ
    select
      q.topic_arn as from_id,
      s.subscription_arn as to_id
    from
      aws_sns_topic as q
      left join aws_sns_topic_subscription as s on s.topic_arn = q.topic_arn
    where
      q.topic_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_from_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_bucket,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'TopicConfigurations')
          when 'array' then (event_notification_configuration -> 'TopicConfigurations')
          else null end
        )
        as t
    where
      t ->> 'TopicArn' = $1;
  EOQ

  param "arn" {}
}

edge "aws_sns_topic_from_s3_bucket_edge" {
  title = "send notifications"

  sql = <<-EOQ
    select
      arn as from_id,
      $1 as to_id
    from
      aws_s3_bucket,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'TopicConfigurations')
          when 'array' then (event_notification_configuration -> 'TopicConfigurations')
          else null end
        )
        as t
    where
      t ->> 'TopicArn' = $1;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_from_rds_db_instance_node" {
  category = category.aws_rds_db_instance

  sql = <<-EOQ
    select
      i.arn as id,
      i.title as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'DB Instance Identifier', i.db_instance_identifier,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_instance as i,
      aws_rds_db_event_subscription as e
    where
      e.source_type = 'db-instance'
      and (source_ids_list is null or i.db_instance_identifier in (select trim((s::text ), '""') from aws_rds_db_event_subscription,
      jsonb_array_elements(source_ids_list) as s)
      )
      and e.sns_topic_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_sns_topic_from_rds_db_instance_edge" {
  title = "event subscription"

  sql = <<-EOQ
    select
      i.arn as from_id,
      t.topic_arn as to_id
    from
      aws_sns_topic as t,
      aws_rds_db_instance as i,
      aws_rds_db_event_subscription as e
    where
      e.source_type = 'db-instance'
      and (source_ids_list is null or i.db_instance_identifier in
        (
        select
          trim((s::text ), '""')
        from
          aws_rds_db_event_subscription,
          jsonb_array_elements(source_ids_list) as s
        )
      )
      and t.topic_arn = e.sns_topic_arn
      and topic_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_from_redshift_cluster_node" {
  category = category.aws_redshift_cluster

  sql = <<-EOQ
    select
      c.arn as id,
      c.title as title,
      jsonb_build_object(
        'ARN', c.arn,
        'Cluster Identifier', c.cluster_identifier,
        'Event Categories List', case when event_categories_list is null then '["ALL"]' else event_categories_list end,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_redshift_cluster as c,
      aws_redshift_event_subscription as e
    where
      (e.source_type = 'cluster' or e.source_type is null)
      and (source_ids_list is null or c.cluster_identifier in (select trim((s::text ), '""') from aws_redshift_event_subscription,
      jsonb_array_elements(source_ids_list) as s)
      )
      and e.sns_topic_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_sns_topic_from_redshift_cluster_edge" {
  title = "event subscription"

  sql = <<-EOQ
    select
      c.arn as from_id,
      t.topic_arn as to_id
    from
      aws_sns_topic as t,
      aws_redshift_cluster as c,
      aws_redshift_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(e.source_ids_list)
          when 'array' then (e.source_ids_list)
          else null end
      ) as s
    where
      (e.source_type = 'cluster' or e.source_type is null)
      and (source_ids_list is null or c.cluster_identifier in (select trim((s::text ), '""') from aws_redshift_event_subscription,
      jsonb_array_elements(source_ids_list) as s)
      )
      and t.topic_arn = e.sns_topic_arn
      and t.topic_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_from_cloudtrail_trail_node" {
  category = category.aws_cloudtrail_trail

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', t.arn,
        'Is Logging', t.is_logging,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_cloudtrail_trail as t
    where
      t.sns_topic_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_sns_topic_from_cloudtrail_trail_edge" {
  title = "send notifications"

  sql = <<-EOQ
    select
      c.arn as from_id,
      $1 as to_id
    from
      aws_sns_topic as t
      left join aws_cloudtrail_trail as c on t.topic_arn = c.sns_topic_arn
    where
      t.topic_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_from_cloudformation_stack_node" {
  category = category.aws_cloudformation_stack

  sql = <<-EOQ
    select
      s.id as id,
      title as title,
      jsonb_build_object(
        'ARN', s.id,
        'Last Updated Time', s.last_updated_time,
        'Status', s.status,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_cloudformation_stack as s,
      jsonb_array_elements(
        case jsonb_typeof(notification_arns)
          when 'array' then (notification_arns)
          else null end
      ) n
    where
      trim((n::text ), '""') = $1;
  EOQ

  param "arn" {}
}

edge "aws_sns_topic_from_cloudformation_stack_edge" {
  title = "send notifications"

  sql = <<-EOQ
    select
      s.id as from_id,
      t.topic_arn as to_id
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
      and t.topic_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sns_topic_from_aws_elasticache_cluster_node" {
  category = category.aws_elasticache_cluster

  sql = <<-EOQ
    select
      c.arn as id,
      c.title as title,
      jsonb_build_object(
        'ARN', c.arn,
        'ID', c.cache_cluster_id,
        'Status', c.cache_cluster_status,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_elasticache_cluster as c
    where
      c.notification_configuration ->> 'TopicArn' = $1;
  EOQ

  param "arn" {}
}

edge "aws_sns_topic_from_aws_elasticache_cluster_edge" {
  title = "send notifications"

  sql = <<-EOQ
    select
      c.arn as from_id,
      t.topic_arn as to_id
    from
      aws_sns_topic as t,
      aws_elasticache_cluster as c
    where
      t.topic_arn = (c.notification_configuration ->> 'TopicArn')
      and t.topic_arn = $1;
  EOQ

  param "arn" {}
}
