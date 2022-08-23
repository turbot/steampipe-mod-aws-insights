dashboard "aws_sqs_queue_detail" {

  title         = "AWS SQS Queue Detail"
  documentation = file("./dashboards/sqs/docs/sqs_queue_detail.md")

  tags = merge(local.sqs_common_tags, {
    type = "Detail"
  })


  input "queue_arn" {
    title = "Select a Queue:"
    sql   = query.aws_sqs_queue_input.sql
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
      type  = "graph"
      title = "Relationships"
      query = query.aws_sqs_queue_relationships_graph
      args = {
        arn = self.input.queue_arn.value
      }

      category "aws_sqs_queue" {
        icon = local.aws_sqs_queue_icon
      }

      category "aws_sns_topic_subscription" {
        color = "blue"
      }

      category "dead_letter_queue" {
        color = "red"
      }

      category "aws_kms_key" {
        icon = local.aws_kms_key_icon
        // cyclic dependency prevents use of url_path, hardcode for now
        # href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
        href = "/aws_insights.dashboard.aws_kms_key_detail?input.key_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_s3_bucket" {
        icon = local.aws_s3_bucket_icon
        href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_vpc_endpoint" {
        icon = local.aws_vpc_endpoint_icon
      }

      category "aws_vpc" {
        icon = local.aws_vpc_icon
        href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
      }

      category "aws_lambda_function" {
        icon = local.aws_lambda_function_icon
        href = "${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_eventbridge_rule" {
        icon = local.aws_eventbridge_rule_icon
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
      max_message_size  as "Max Message Size",
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

query "aws_sqs_queue_relationships_graph" {
  sql = <<-EOQ
    with queue as (
      select
        *
      from
        aws_sqs_queue
      where
        queue_arn = $1
    )
    select
      null as from_id,
      null as to_id,
      queue_arn as id,
      title as title,
      'aws_sqs_queue' as category,
      jsonb_build_object(
        'ARN', queue_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      queue

    -- To SNS topic subscriptions (node)
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
    where
      endpoint = $1

    -- To SNS topic subscriptions (edge)
    union all
    select
      q.queue_arn as from_id,
      s.subscription_arn as to_id,
      null as id,
      'subscibe to' as title,
      'sqs_queue_to_sns_topic_subscription' as category,
      jsonb_build_object(
        'ARN', s.subscription_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      queue as q
      left join aws_sns_topic_subscription as s on s.endpoint = q.queue_arn

    -- To SQS queues (node)
    union all
    select
      null as from_id,
      null as to_id,
      split_part(redrive_policy ->> 'deadLetterTargetArn', ':', 6) as id,
      split_part(redrive_policy ->> 'deadLetterTargetArn', ':', 6) as title,
      'aws_sqs_queue' as category,
      jsonb_build_object(
        'ARN', queue_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      queue
    where
      redrive_policy ->> 'deadLetterTargetArn' is not null

    -- To SQS queue (edge)
    union all
    select
      queue_arn as from_id,
      split_part(redrive_policy ->> 'deadLetterTargetArn', ':', 6) as to_id,
      null as id,
      'dead letter queue' as title,
      'sqs_queue_to_sqs_queue' as category,
      jsonb_build_object(
        'ARN', queue_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      queue
     where
      redrive_policy ->> 'deadLetterTargetArn' is not null

  -- To KMS keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_kms_key,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasName' = (select kms_master_key_id from queue)
      and region = (select region from queue)

    -- To KMS keys (edge)
    union all
    select
      q.queue_arn as from_id,
      k.arn as to_id,
      null as id,
      'encrypts with' as title,
      'sqs_queue_to_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      queue as q,
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasName' = q.kms_master_key_id
      and k.region = q.region

    -- From S3 buckets (node)
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
        case jsonb_typeof(event_notification_configuration -> 'QueueConfigurations')
          when 'array' then (event_notification_configuration -> 'QueueConfigurations')
          else null end
        )
        as q
    where
      q ->> 'QueueArn' = $1

    -- From S3 buckets (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'event notification' as title,
      's3_bucket_to_sqs_queue' as category,
      jsonb_build_object(
        'ARN', arn,
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
      q ->> 'QueueArn' = $1

    -- From Lambda functions (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_lambda_function
    where
      dead_letter_config_target_arn = $1

    -- From Lambda functions (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'dead letter config' as title,
      'lambda_function_to_sqs_queue' as category,
      jsonb_build_object(
        'ARN', l.arn,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      aws_lambda_function as l
    where
      dead_letter_config_target_arn = $1

  -- From VPC endpoints (node)
    union all
    select
      null as from_id,
      null as to_id,
      vpc_endpoint_id as id,
      title as title,
      'aws_vpc_endpoint' as category,
      jsonb_build_object(
        'ID', vpc_endpoint_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_endpoint,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = $1

    -- From VPC endpoints (edge)
    union all
    select
      vpc_endpoint_id as from_id,
      $1 as to_id,
      null as id,
      'uses' as title,
      'vpc_endpoint_to_sqs_queue' as category,
      jsonb_build_object(
        'ID', vpc_endpoint_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_endpoint,
      jsonb_array_elements(policy_std -> 'Statement') as s,
        jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = $1

    -- From VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      e.vpc_id as id,
      e.vpc_id as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ID', vpc_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_endpoint as e,
      jsonb_array_elements(e.policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = $1

    -- From VPC (edge)
    union all
    select
      vpc_id as from_id,
      vpc_endpoint_id as to_id,
      null as id,
      'uses' as title,
      'vpc_to_vpc_endpoint' as category,
      jsonb_build_object(
        'ID', vpc_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_endpoint,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = $1

    -- From Eventbridge rules (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_eventbridge_rule' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_eventbridge_rule,
      jsonb_array_elements(targets) as t
    where
      t ->> 'Arn' = $1

    -- From Eventbridge rules (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'target' as title,
      'eventbridge_rule_to_sqs_queue' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Account ID', r.account_id,
        'Region', r.region
      ) as properties
    from
      aws_eventbridge_rule as r,
      jsonb_array_elements(targets) as t
    where
      t ->> 'Arn' = $1
  EOQ

  param "arn" {}
}
