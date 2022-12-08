dashboard "sqs_queue_detail" {

  title         = "AWS SQS Queue Detail"
  documentation = file("./dashboards/sqs/docs/sqs_queue_detail.md")

  tags = merge(local.sqs_common_tags, {
    type = "Detail"
  })


  input "queue_arn" {
    title = "Select a Queue:"
    query = query.sqs_queue_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.sqs_queue_encryption
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2
      query = query.sqs_queue_content_based_deduplication
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2
      query = query.sqs_queue_delay_seconds
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2
      query = query.sqs_queue_message_retention_seconds
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

      with "eventbridge_rules" {
        sql = <<-EOQ
          select
            arn as eventbridge_rule_arn
          from
            aws_eventbridge_rule as r,
            jsonb_array_elements(targets) as t
          where
            t ->> 'Arn' = $1;
        EOQ

        args = [self.input.queue_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            k.arn as key_arn
          from
            aws_sqs_queue as q,
            aws_kms_key as k,
            jsonb_array_elements(aliases) as a
          where
            a ->> 'AliasName' = q.kms_master_key_id
            and k.region = q.region
            and q.queue_arn = $1;
        EOQ

        args = [self.input.queue_arn.value]
      }

      with "lambda_functions" {
        sql = <<-EOQ
          select
            arn as function_arn
          from
            aws_lambda_function
          where
            dead_letter_config_target_arn = $1;
        EOQ

        args = [self.input.queue_arn.value]
      }

      with "s3_buckets" {
        sql = <<-EOQ
          select
            b.arn as bucket_arn
          from
            aws_s3_bucket as b,
            jsonb_array_elements(event_notification_configuration -> 'QueueConfigurations') as q
          where
            event_notification_configuration -> 'QueueConfigurations' <> 'null'
            and q ->> 'QueueArn' = $1;
        EOQ

        args = [self.input.queue_arn.value]
      }

      with "vpc_endpoints" {
        sql = <<-EOQ
          select
            vpc_endpoint_id
          from
            aws_vpc_endpoint,
            jsonb_array_elements(policy_std -> 'Statement') as s,
            jsonb_array_elements_text(s -> 'Resource') as r
          where
            r = $1;
        EOQ

        args = [self.input.queue_arn.value]
      }

      with "vpc_vpcs" {
        sql = <<-EOQ
          select
            vpc_id
          from
            aws_vpc_endpoint,
            jsonb_array_elements(policy_std -> 'Statement') as s,
            jsonb_array_elements_text(s -> 'Resource') as r
          where
            r = $1;
        EOQ

        args = [self.input.queue_arn.value]
      }

      nodes = [
        node.eventbridge_rule,
        node.kms_key,
        node.lambda_function,
        node.s3_bucket,
        node.sqs_dead_letter_queue,
        node.sqs_queue,
        node.sqs_queue_sns_topic_subscription,
        node.vpc_endpoint,
        node.vpc_vpc
      ]

      edges = [
        edge.eventbridge_rule_to_sqs_queue,
        edge.lambda_function_to_sqs_queue,
        edge.s3_bucket_to_sqs_queue,
        edge.sqs_queue_to_kms_key,
        edge.sqs_queue_to_sns_topic_subscription,
        edge.sqs_queue_to_sqs_dead_letter_queue,
        edge.sqs_queue_to_vpc_endpoint,
        edge.vpc_endpoint_to_vpc
      ]

      args = {
        eventbridge_rule_arns = with.eventbridge_rules.rows[*].eventbridge_rule_arn
        kms_key_arns          = with.kms_keys.rows[*].key_arn
        lambda_function_arns  = with.lambda_functions.rows[*].function_arn
        s3_bucket_arns        = with.s3_buckets.rows[*].bucket_arn
        sqs_queue_arns        = [self.input.queue_arn.value]
        vpc_endpoint_ids      = with.vpc_endpoints.rows[*].vpc_endpoint_id
        vpc_vpc_ids           = with.vpc_vpcs.rows[*].vpc_id
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
        query = query.sqs_queue_overview
        args = {
          queue_arn = self.input.queue_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.sqs_queue_tags_detail
        args = {
          queue_arn = self.input.queue_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Message Details"
        query = query.sqs_queue_message
        args = {
          queue_arn = self.input.queue_arn.value
        }
      }

      table {
        title = "Encryption Details"
        query = query.sqs_queue_encryption_details
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
      query = query.sqs_queue_policy
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

  }

}

query "sqs_queue_input" {
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

query "sqs_queue_encryption" {
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

query "sqs_queue_content_based_deduplication" {
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

query "sqs_queue_delay_seconds" {
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

query "sqs_queue_message_retention_seconds" {
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

query "sqs_queue_overview" {
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

query "sqs_queue_tags_detail" {
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

query "sqs_queue_policy" {
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

query "sqs_queue_message" {
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

query "sqs_queue_encryption_details" {
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
