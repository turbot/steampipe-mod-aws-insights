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
      width = 2
      query = query.sns_topic_encryption_status
      args = {
        arn = self.input.topic_arn.value
      }
    }

    card {
      query = query.sns_topic_subscriptions_confirmed_count
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

      with "cloudtrail_trails" {
        sql = <<-EOQ
          select
            arn as trail_arn
          from
            aws_cloudtrail_trail
          where
            sns_topic_arn = $1;
        EOQ

        args = [self.input.topic_arn.value]
      }

      with "elasticache_clusters" {
        sql = <<-EOQ
          select
            arn as elasticache_cluster_arn
          from
            aws_elasticache_cluster
          where
            notification_configuration ->> 'TopicArn' = $1;
        EOQ

        args = [self.input.topic_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_master_key_id as key_arn
          from
            aws_sns_topic
          where
            kms_master_key_id is not null
            and topic_arn = $1;
        EOQ

        args = [self.input.topic_arn.value]
      }

      with "rds_db_instances" {
        sql = <<-EOQ
          select
            i.arn as db_instance_arn
          from
            aws_rds_db_event_subscription as s,
            jsonb_array_elements_text(source_ids_list) as ids
            join aws_rds_db_instance as i
            on ids = i.db_instance_identifier
          where
            s.sns_topic_arn = $1;
        EOQ

        args = [self.input.topic_arn.value]
      }

      with "redshift_clusters" {
        sql = <<-EOQ
          select
            c.arn as cluster_arn
          from
            aws_redshift_event_subscription as s,
            jsonb_array_elements_text(source_ids_list) as ids
            join aws_redshift_cluster as c
            on ids = c.cluster_identifier
          where
            s.sns_topic_arn = $1;
        EOQ

        args = [self.input.topic_arn.value]
      }

      with "s3_buckets" {
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
            t ->> 'TopicArn' = $1;
        EOQ

        args = [self.input.topic_arn.value]
      }

      nodes = [
        node.cloudformation_stack,
        node.cloudtrail_trail,
        node.elasticache_cluster,
        node.kms_key,
        node.rds_db_instance,
        node.redshift_cluster,
        node.s3_bucket,
        node.sns_topic,
        node.sns_topic_subscription
      ]

      edges = [
        edge.cloudformation_stack_to_sns_topic,
        edge.cloudtrail_trail_to_sns_topic,
        edge.elasticache_cluster_to_sns_topic,
        edge.rds_db_instance_to_sns_topic,
        edge.redshift_cluster_to_sns_topic,
        edge.s3_bucket_to_sns_topic,
        edge.sns_topic_to_kms_key,
        edge.sns_topic_to_sns_topic_subscription
      ]

      args = {
        cloudtrail_trail_arns    = with.cloudtrail_trails.rows[*].trail_arn
        elasticache_cluster_arns = with.elasticache_clusters.rows[*].elasticache_cluster_arn
        kms_key_arns             = with.kms_keys.rows[*].key_arn
        rds_db_instance_arns     = with.rds_db_instances.rows[*].db_instance_arn
        redshift_cluster_arns    = with.redshift_clusters.rows[*].cluster_arn
        s3_bucket_arns           = with.s3_buckets.rows[*].bucket_arn
        sns_topic_arns           = [self.input.topic_arn.value]
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
        args = {
          arn = self.input.topic_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.sns_topic_tags
        args = {
          arn = self.input.topic_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Subscription Counts"
        query = query.sns_topic_subscriptions
        args = {
          arn = self.input.topic_arn.value
        }
      }

    }

    container {
      width = 12

      table {
        title = "Effective Delivery Policy"
        query = query.sns_topic_delivery_policy
        args = {
          arn = self.input.topic_arn.value
        }
      }

      table {
        title = "Policy"
        query = query.sns_topic_policy_standard
        args = {
          arn = self.input.topic_arn.value
        }
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

query "sns_topic_encryption_status" {
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

query "sns_topic_subscriptions_confirmed_count" {
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
      topic_arn = $1;
  EOQ

  param "arn" {}
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
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "sns_topic_subscriptions" {
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
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "sns_topic_policy_standard" {
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
