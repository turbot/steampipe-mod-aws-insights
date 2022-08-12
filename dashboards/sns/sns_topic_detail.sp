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
      type  = "graph"
      title = "Relationships"
      query = query.aws_sns_topic_relationships_graph
      args = {
        arn = self.input.topic_arn.value
      }

      category "aws_sns_topic" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/sns_topic_light.svg"))
        # href  = "${dashboard.aws_sns_topic_detail.url_path}?input.topic_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_kms_key" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_light.svg"))
        href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_sns_topic_subscription" {
        color = "green"
      }

      category "aws_s3_bucket" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/s3_bucket_light.svg"))
        href  = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_rds_db_instance" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_light.svg"))
        href  = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_redshift_cluster" {
        # icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/aws_redshift_cluster.svg"))
        href  = "${dashboard.aws_redshift_cluster_detail.url_path}?input.cluster_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_cloudtrail_trail" {
        # icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/aws_s3_bucket.svg"))
        href  = "${dashboard.aws_cloudtrail_trail_detail.url_path}?input.trail_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_cloudformation_stack" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cloudformation_stack_light.svg"))
      }

      category "aws_elasticache_cluster" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/elasticache_for_redis_light.svg"))
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

query "aws_sns_topic_relationships_graph" {
  sql = <<-EOQ
  with topic as (select * from aws_sns_topic where topic_arn = $1)

    select
      null as from_id,
      null as to_id,
      topic_arn as id,
      title as title,
      'aws_sns_topic' as category,
      jsonb_build_object(
        'ARN', topic_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      topic

    -- To Kms key (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.arn as id,
      k.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      topic as q
      left join aws_kms_key as k on k.id = split_part(q.kms_master_key_id, '/', 2)
    where
      k.region = q.region

    -- To Kms key (edge)
    union all
    select
      q.topic_arn as from_id,
      k.arn as to_id,
      null as id,
      'Encrypted With' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      topic as q
      left join aws_kms_key as k on k.id = split_part(q.kms_master_key_id, '/', 2)
    where
      k.region = q.region

    -- To Subscription topics (node)
    union all
    select
      null as from_id,
      null as to_id,
      subscription_arn as id,
      title as title,
      'aws_sns_topic_subscription' as category,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sns_topic_subscription
    where topic_arn = $1

    -- To Subscription Topics (edge)
    union all
    select
      q.topic_arn as from_id,
      s.subscription_arn as to_id,
      null as id,
      'subscibe to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', s.subscription_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      topic as q
    left join aws_sns_topic_subscription as s on s.topic_arn = q.topic_arn

  -- From S3 Buckets (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_s3_bucket' as category,
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
      t ->> 'TopicArn'  = $1

    -- From S3 Buckets (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
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
      t ->> 'TopicArn'  = $1

    -- From RDS DB Instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      i.arn as id,
      i.title as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_instance as i,
      aws_rds_db_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(source_ids_list)
          when 'array' then (source_ids_list)
          else null end
      ) s
    where
      e.source_type = 'db-instance'
      and (source_ids_list is null or i.db_instance_identifier = trim((s::text ), '""'))
      and e.sns_topic_arn = $1

    -- From RDS DB Instances (edge)
    union all
    select
      i.arn as from_id,
      t.topic_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Event Categories List', case when event_categories_list is null then '["ALL"]' else event_categories_list end,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      topic as t,
      aws_rds_db_instance as i,
      aws_rds_db_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(e.source_ids_list)
          when 'array' then (e.source_ids_list)
          else null end
      ) as s
    where
      e.source_type = 'db-instance'
      and (e.source_ids_list is null or i.db_instance_identifier = trim((s::text ), '""'))
      and t.topic_arn = e.sns_topic_arn

    -- From Redshift clusters (node)
    union all
    select
      null as from_id,
      null as to_id,
      c.arn as id,
      c.title as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_redshift_cluster as c,
      aws_redshift_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(source_ids_list)
          when 'array' then (source_ids_list)
          else null end
      ) s
    where
      (e.source_type = 'cluster' or e.source_type is null)
      and (source_ids_list is null or c.cluster_identifier = trim((s::text ), '""'))
      and e.sns_topic_arn = $1

    -- From Redshift clusters (edge)
    union all
    select
      c.arn as from_id,
      t.topic_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Event Categories List', case when event_categories_list is null then '["ALL"]' else event_categories_list end,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      topic as t,
      aws_redshift_cluster as c,
      aws_redshift_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(e.source_ids_list)
          when 'array' then (e.source_ids_list)
          else null end
      ) as s
    where
      (e.source_type = 'cluster' or e.source_type is null)
      and (e.source_ids_list is null or c.cluster_identifier = trim((s::text ), '""'))
      and t.topic_arn = e.sns_topic_arn

    -- From Cloudtrail Trails (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID',t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_cloudtrail_trail as t
    where
      t.sns_topic_arn  = $1

    -- From Cloudtrail Trails (edge)
    union all
    select
      c.arn as from_id,
      $1 as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      topic as t
      left join aws_cloudtrail_trail as c on t.topic_arn = c.sns_topic_arn

    -- From Clouformation Stacks (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.id as id,
      s.title as title,
      'aws_cloudformation_stack' as category,
      jsonb_build_object(
        'ARN', s.id,
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
      trim((n::text ), '""') = $1

    -- From Clouformation Stacks (edge)
    union all
    select
      s.id as from_id,
      t.topic_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ID', s.id ,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      topic as t,
      aws_cloudformation_stack as s,
      jsonb_array_elements(
        case jsonb_typeof(notification_arns)
          when 'array' then (notification_arns)
          else null end
      ) n
    where
      t.topic_arn = trim((n::text ), '""')

    -- From ElastiCache Clusters (node)
    union all
    select
      null as from_id,
      null as to_id,
      c.arn as id,
      c.title as title,
      'aws_elasticache_cluster' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_elasticache_cluster as c
    where
      c.notification_configuration ->> 'TopicArn' = $1

    -- From ElastiCache Clusters (edge)
    union all
    select
      c.arn as from_id,
      t.topic_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      topic as t,
      aws_elasticache_cluster as c
    where
      t.topic_arn = (c.notification_configuration ->> 'TopicArn')
    order by
      category,
      from_id,
      to_id;

  EOQ
  param "arn" {}
}