dashboard "aws_sqs_queue_detail" {

  title         = "AWS SQS Queue Detail"
  documentation = file("./dashboards/sqs/docs/sqs_queue_detail.md")

  tags = merge(local.sqs_common_tags, {
    type = "Detail"
  })


  input "queue_arn" {
    title = "Select a Queue:"
    query = query.aws_sqs_queue_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_sqs_queue_encryption
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_sqs_queue_content_based_deduplication
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_sqs_queue_delay_seconds
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_sqs_queue_message_retention_seconds
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_sqs_queue_node,
        node.aws_sqs_queue_to_sns_topic_subscription_node,
        node.aws_sqs_queue_to_sqs_queue_node,
        node.aws_sqs_queue_to_kms_key_node,
        node.aws_sqs_queue_from_s3_bucket_node,
        node.aws_sqs_queue_from_lambda_function_node,
        node.aws_sqs_queue_from_vpc_endpoint_node,
        node.aws_sqs_queue_from_vpc_node,
        node.aws_sqs_queue_from_eventbridge_rule_node
      ]

      edges = [
        edge.aws_sqs_queue_to_sns_topic_subscription_edge,
        edge.aws_sqs_queue_to_sqs_queue_edge,
        edge.aws_sqs_queue_to_kms_key_edge,
        edge.aws_sqs_queue_from_s3_bucket_edge,
        edge.aws_sqs_queue_from_lambda_function_edge,
        edge.aws_sqs_queue_from_vpc_endpoint_edge,
        edge.aws_sqs_queue_vpc_endpoint_from_vpc_edge,
        edge.aws_sqs_queue_from_eventbridge_rule_edge
      ]

      args = {
        arn = self.input.queue_arn.value
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
        query = query.aws_sqs_queue_overview
        args = {
          queue_arn = self.input.queue_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_sqs_queue_tags_detail
        args = {
          queue_arn = self.input.queue_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Message Details"
        query = query.aws_sqs_queue_message
        args = {
          queue_arn = self.input.queue_arn.value
        }
      }

      table {
        title = "Encryption Details"
        query = query.aws_sqs_queue_encryption_details
        args = {
          queue_arn = self.input.queue_arn.value
        }
      }

    }

  }

  container {

    width = 12

    table {
      title = "Policy"
      query = query.aws_sqs_queue_policy
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

  }

}

query "aws_sqs_queue_input" {
  sql = <<-EOQ
    select
      title as label,
      queue_arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_sqs_queue
    order by
      title;
  EOQ
}

query "aws_sqs_queue_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_master_key_id is not null then 'Enabled' else 'Disabled' end as value,
      case when kms_master_key_id is not null then 'ok' else 'alert' end as "type"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_content_based_deduplication" {
  sql = <<-EOQ
    select
      'Content Based Deduplication' as label,
      content_based_deduplication as value
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_delay_seconds" {
  sql = <<-EOQ
    select
      'Delay Seconds' as label,
      delay_seconds as value
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_message_retention_seconds" {
  sql = <<-EOQ
    select
      'Message Retention Seconds' as label,
      message_retention_seconds as value
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_overview" {
  sql = <<-EOQ
    select
      queue_url as "Queue URL",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      queue_arn as "ARN"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_tags_detail" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        aws_sqs_queue
      where
        queue_arn = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags)
    order by
      key;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_policy" {
  sql = <<-EOQ
    select
      p ->> 'Sid' as "SID",
      p ->> 'Effect' as "Effect",
      p -> 'Principal' as "Principal",
      p -> 'Action'  as "Action",
      p -> 'Resource' as "Resource"

    from
      aws_sqs_queue,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_message" {
  sql = <<-EOQ
    select
      max_message_size as "Max Message Size",
      message_retention_seconds as "Message Retention Seconds",
      visibility_timeout_seconds as "Visibility Timeout Seconds"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_encryption_details" {
  sql = <<-EOQ
    select
       case when kms_master_key_id is not null then 'Enabled' else 'Disabled' end as "Encryption",
       kms_master_key_id as "KMS Master Key ID"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

node "aws_sqs_queue_node" {
  category = category.aws_sqs_queue

  sql = <<-EOQ
    select
      queue_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', queue_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sqs_queue_to_sns_topic_subscription_node" {
  category = category.aws_sns_topic_subscription

  sql = <<-EOQ
    select
      subscription_arn as id,
      left(title,8) as title,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sns_topic_subscription
    where
      endpoint = $1;
  EOQ

  param "arn" {}
}

edge "aws_sqs_queue_to_sns_topic_subscription_edge" {
  title = "subscription"

  sql = <<-EOQ
    select
      q.queue_arn as from_id,
      s.subscription_arn as to_id
    from
      aws_sqs_queue as q
      left join aws_sns_topic_subscription as s on s.endpoint = q.queue_arn
      and q.queue_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sqs_queue_to_sqs_queue_node" {
  category = category.aws_sqs_queue

  sql = <<-EOQ
    select
      redrive_policy ->> 'deadLetterTargetArn' as id,
      split_part(redrive_policy ->> 'deadLetterTargetArn', ':', 6) as title,
      jsonb_build_object(
        'ARN', queue_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sqs_queue
    where
      redrive_policy ->> 'deadLetterTargetArn' is not null
      and queue_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_sqs_queue_to_sqs_queue_edge" {
  title = "dead letter queue"

  sql = <<-EOQ
    select
      queue_arn as from_id,
      redrive_policy ->> 'deadLetterTargetArn' as to_id
    from
      aws_sqs_queue
    where
      redrive_policy ->> 'deadLetterTargetArn' is not null
      and queue_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sqs_queue_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Id', id,
        'Enabled', enabled::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_kms_key,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasName' in (select kms_master_key_id from aws_sqs_queue where queue_arn = $1)
      and region in (select region from aws_sqs_queue where queue_arn = $1);
  EOQ

  param "arn" {}
}

edge "aws_sqs_queue_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      q.queue_arn as from_id,
      k.arn as to_id
    from
      aws_sqs_queue as q,
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasName' = q.kms_master_key_id
      and k.region = q.region
      and q.queue_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sqs_queue_from_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Versioning Enabled', versioning_enabled::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_bucket,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'QueueConfigurations')
          when 'array' then (event_notification_configuration -> 'QueueConfigurations')
          else null end
        )
        as q
    where
      q ->> 'QueueArn' = $1;
  EOQ

  param "arn" {}
}

edge "aws_sqs_queue_from_s3_bucket_edge" {
  title = "queues"

  sql = <<-EOQ
    select
      arn as from_id,
      $1 as to_id
    from
      aws_s3_bucket,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'QueueConfigurations')
          when 'array' then (event_notification_configuration -> 'QueueConfigurations')
          else null end
        )
        as q
    where
      q ->> 'QueueArn' = $1;
  EOQ

  param "arn" {}
}

node "aws_sqs_queue_from_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'State', state,
        'Runtime', runtime,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_lambda_function
    where
      dead_letter_config_target_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_sqs_queue_from_lambda_function_edge" {
  title = "queues"

  sql = <<-EOQ
    select
      arn as from_id,
      $1 as to_id
    from
      aws_lambda_function as l
    where
      dead_letter_config_target_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_sqs_queue_from_vpc_endpoint_node" {
  category = category.aws_vpc_endpoint

  sql = <<-EOQ
    select
      vpc_endpoint_id as id,
      title as title,
      jsonb_build_object(
        'ID', vpc_endpoint_id,
        'State', state,
        'Service Name', service_name,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_endpoint,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = $1;
  EOQ

  param "arn" {}
}

edge "aws_sqs_queue_from_vpc_endpoint_edge" {
  title = "queues"

  sql = <<-EOQ
    select
      vpc_endpoint_id as from_id,
      $1 as to_id
    from
      aws_vpc_endpoint,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = $1;
  EOQ

  param "arn" {}
}

node "aws_sqs_queue_from_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      e.vpc_id as id,
      v.title as title,
      jsonb_build_object(
        'VPC ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_vpc_endpoint as e,
      jsonb_array_elements(e.policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r,
      aws_vpc as v
    where
      v.vpc_id = e.vpc_id
      and r = $1;
  EOQ

  param "arn" {}
}

edge "aws_sqs_queue_vpc_endpoint_from_vpc_edge" {
  title = "vpc endpoint"

  sql = <<-EOQ
    select
      e.vpc_id as from_id,
      e.vpc_endpoint_id as to_id
    from
      aws_vpc_endpoint as e,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
      , aws_vpc as v
    where
      v.vpc_id = e.vpc_id
      and r = $1;
  EOQ

  param "arn" {}
}

node "aws_sqs_queue_from_eventbridge_rule_node" {
  category = category.aws_eventbridge_rule

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'State', state,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_eventbridge_rule,
      jsonb_array_elements(targets) as t
    where
      t ->> 'Arn' = $1;
  EOQ

  param "arn" {}
}

edge "aws_sqs_queue_from_eventbridge_rule_edge" {
  title = "target as"

  sql = <<-EOQ
    select
      arn as from_id,
      $1 as to_id
    from
      aws_eventbridge_rule as r,
      jsonb_array_elements(targets) as t
    where
      t ->> 'Arn' = $1;
  EOQ

  param "arn" {}
}
