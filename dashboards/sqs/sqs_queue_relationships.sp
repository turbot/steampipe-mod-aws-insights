dashboard "aws_sqs_queue_relationships" {

  title         = "AWS SQS Queue Relationships"
  documentation = file("./dashboards/sqs/docs/sqs_queue_relationships.md")

  tags = merge(local.sqs_common_tags, {
    type = "Relationships"
  })


  input "queue_arn" {
    title = "Select a Queue:"
    sql   = query.aws_sqs_queue.sql
    width = 4
  }

   graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_sqs_queue_graph_from_queue
    args = {
      arn = self.input.queue_arn.value
    }

      category "aws_sqs_queue" {
        icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/sqs_queue_light.svg"))
        color = "blue"
        href  = "${dashboard.aws_sqs_queue_detail.url_path}?input.queue_arn={{.properties.'ARN' | @uri}}"
      }

      category "dead_letter_queue" {
        color = "red"
        href  = "${dashboard.aws_sqs_queue_detail.url_path}?input.queue_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_kms_key" {
        color = "orange"
        icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/kms_key_light.svg"))
        href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
      }

       category "aws_sns_topic_subscription" {
        color = "green"
      }

    }

   graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_sqs_queue_graph_to_queue
    args = {
      arn = self.input.queue_arn.value
    }

    category "aws_sqs_queue" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/sqs_queue_light.svg"))
      color = "blue"
      href  = "${dashboard.aws_sqs_queue_detail.url_path}?input.queue_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_s3_bucket" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/s3_bucket_light.svg"))
      color = "orange"
      href  = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_vpc_endpoint" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/vpc_endpoint_light.svg"))
      color = "orange"
    }

    category "aws_vpc" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
      color = "orange"
      href  = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
    }

  }

}

query "aws_sqs_queue" {
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

query "aws_sqs_queue_graph_from_queue" {
  sql = <<-EOQ
    with queue as (select * from aws_sqs_queue where queue_arn = $1)

    -- queue node
    select
      null as from_id,
      null as to_id,
      title as id,
      title as title,
      'aws_sqs_queue' as category,
      jsonb_build_object(
        'ARN', queue_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      queue

    -- Subscription queue Nodes
    union all
    select
      null as from_id,
      null as to_id,
      title as id,
      title as title,
      'aws_sns_topic_subscription' as category,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sns_topic_subscription
    where endpoint = $1

    -- Subscription queue Edges
    union all
    select
      q.title as from_id,
      s.title as to_id,
      null as id,
      'Subscibe To' as title,
      'subscibe_to' as category,
      jsonb_build_object(
        'ARN', q.queue_arn,
        'Account ID', q.account_id,
        'Region', q.region
      ) as properties
    from
      queue as q
    left join aws_sns_topic_subscription as s on  s.endpoint = q.queue_arn


    -- Dead Letter queue Nodes
    union all
    select
      null as from_id,
      null as to_id,
      split_part(redrive_policy ->> 'deadLetterTargetArn', ':', 6)  as id,
      redrive_policy ->> 'deadLetterTargetArn' as title,
      'dead_letter_queue' as category,
      jsonb_build_object(
        'ARN', queue_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      queue
    where redrive_policy ->> 'deadLetterTargetArn' is not null

    -- Dead Letter queue  Edges
    union all
    select
      title as from_id,
      split_part(redrive_policy ->> 'deadLetterTargetArn', ':', 6) as to_id,
      null as id,
      'Dead Letter' as title,
      'dead_letter' as category,
      jsonb_build_object(
        'ARN', queue_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      queue
     where redrive_policy ->> 'deadLetterTargetArn' is not null

 -- Kms key Nodes
    union all
    select
      null as from_id,
      null as to_id,
      title as id,
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
    where a ->> 'AliasName' = (select kms_master_key_id from queue)
    and region = (select region from queue)

    -- Kms key Edges
    union all
    select
      q.title as from_id,
      k.title as to_id,
      null as id,
      'Encrypted With' as title,
      'encrypted_with' as category,
      jsonb_build_object(
        'ARN', q.queue_arn,
        'Account ID', q.account_id,
        'Region', q.region
      ) as properties
    from
      queue as q,
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasName' = q.kms_master_key_id
      and k.region = q.region
  EOQ
  param "arn" {}
}

query "aws_sqs_queue_graph_to_queue" {
  sql = <<-EOQ
    with queue as (select * from aws_sqs_queue where queue_arn = $1)
    -- queue node
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

  -- Buckets that use me - nodes
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
      q ->> 'QueueArn'  = $1

    -- Buckets that use me - edges
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
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
      q ->> 'QueueArn'  = $1


  -- VPC endpoint that use me - nodes
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

    --  VPC endpoint that use me  - edges
    union all
    select
      vpc_endpoint_id as from_id,
      $1 as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
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

    --  VPC ID that use me  - mode
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

        --  VPC that use me  - edges
    union all
    select
      vpc_id as from_id,
      vpc_endpoint_id as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
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

  EOQ
  param "arn" {}
}