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
      width = 3
      query = query.sqs_queue_encryption
      args  = [self.input.queue_arn.value]
    }

    card {
      width = 3
      query = query.sqs_queue_content_based_deduplication
      args  = [self.input.queue_arn.value]
    }

    card {
      width = 3
      query = query.sqs_queue_delay_seconds
      args  = [self.input.queue_arn.value]
    }

    card {
      width = 3
      query = query.sqs_queue_message_retention_seconds
      args  = [self.input.queue_arn.value]
    }

  }

  with "eventbridge_rules_for_sqs_queue" {
    query = query.eventbridge_rules_for_sqs_queue
    args  = [self.input.queue_arn.value]
  }

  with "kms_keys_for_sqs_queue" {
    query = query.kms_keys_for_sqs_queue
    args  = [self.input.queue_arn.value]
  }

  with "lambda_functions_for_sqs_queue" {
    query = query.lambda_functions_for_sqs_queue
    args  = [self.input.queue_arn.value]
  }

  with "queue_policy_std_for_sqs_queue" {
    query = query.queue_policy_std_for_sqs_queue
    args  = [self.input.queue_arn.value]
  }

  with "s3_buckets_for_sqs_queue" {
    query = query.s3_buckets_for_sqs_queue
    args  = [self.input.queue_arn.value]
  }

  with "vpc_endpoints_for_sqs_queue" {
    query = query.vpc_endpoints_for_sqs_queue
    args  = [self.input.queue_arn.value]
  }

  with "vpc_vpcs_for_sqs_queue" {
    query = query.vpc_vpcs_for_sqs_queue
    args  = [self.input.queue_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.eventbridge_rule
        args = {
          eventbridge_rule_arns = with.eventbridge_rules_for_sqs_queue.rows[*].eventbridge_rule_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_sqs_queue.rows[*].key_arn
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions_for_sqs_queue.rows[*].function_arn
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.s3_buckets_for_sqs_queue.rows[*].bucket_arn
        }
      }

      node {
        base = node.sqs_dead_letter_queue
        args = {
          sqs_queue_arns = [self.input.queue_arn.value]
        }
      }

      node {
        base = node.sqs_queue
        args = {
          sqs_queue_arns = [self.input.queue_arn.value]
        }
      }

      node {
        base = node.sqs_queue_sns_topic_subscription
        args = {
          sqs_queue_arns = [self.input.queue_arn.value]
        }
      }

      node {
        base = node.vpc_endpoint
        args = {
          vpc_endpoint_ids = with.vpc_endpoints_for_sqs_queue.rows[*].vpc_endpoint_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_sqs_queue.rows[*].vpc_id
        }
      }

      edge {
        base = edge.eventbridge_rule_to_sqs_queue
        args = {
          eventbridge_rule_arns = with.eventbridge_rules_for_sqs_queue.rows[*].eventbridge_rule_arn
        }
      }

      edge {
        base = edge.lambda_function_to_sqs_queue
        args = {
          sqs_queue_arns = [self.input.queue_arn.value]
        }
      }

      edge {
        base = edge.s3_bucket_to_sqs_queue
        args = {
          s3_bucket_arns = with.s3_buckets_for_sqs_queue.rows[*].bucket_arn
        }
      }

      edge {
        base = edge.sqs_queue_to_kms_key
        args = {
          sqs_queue_arns = [self.input.queue_arn.value]
        }
      }

      edge {
        base = edge.sqs_queue_to_sns_topic_subscription
        args = {
          sqs_queue_arns = [self.input.queue_arn.value]
        }
      }

      edge {
        base = edge.sqs_queue_to_sqs_dead_letter_queue
        args = {
          sqs_queue_arns = [self.input.queue_arn.value]
        }
      }

      edge {
        base = edge.sqs_queue_to_vpc_endpoint
        args = {
          sqs_queue_arns = [self.input.queue_arn.value]
        }
      }

      edge {
        base = edge.vpc_endpoint_to_vpc_vpc
        args = {
          vpc_endpoint_ids = with.vpc_endpoints_for_sqs_queue.rows[*].vpc_endpoint_id
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
        query = query.sqs_queue_overview
        args  = [self.input.queue_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.sqs_queue_tags_detail
        args  = [self.input.queue_arn.value]
      }

    }

    container {

      width = 6

      table {
        title = "Message Details"
        query = query.sqs_queue_message
        args  = [self.input.queue_arn.value]
      }

      table {
        title = "Encryption Details"
        query = query.sqs_queue_encryption_details
        args  = [self.input.queue_arn.value]
      }

    }

  }

  graph {
    title = "Resource Policy"
    base  = graph.iam_resource_policy_structure
    args = {
      policy_std = with.queue_policy_std_for_sqs_queue.rows[0].policy_std
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

# card queries

query "sqs_queue_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_master_key_id is not null or sqs_managed_sse_enabled then 'Enabled' else 'Disabled' end as value,
      case when kms_master_key_id is not null or sqs_managed_sse_enabled then 'ok' else 'alert' end as "type"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

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

}

# with queries

query "eventbridge_rules_for_sqs_queue" {
  sql = <<-EOQ
    select
      arn as eventbridge_rule_arn
    from
      aws_eventbridge_rule as r,
      jsonb_array_elements(targets) as t
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and t ->> 'Arn' = $1;
  EOQ
}

query "kms_keys_for_sqs_queue" {
  sql = <<-EOQ
    with sqs_queue as (
      select
        kms_master_key_id,
        queue_arn,
        region,
        account_id
      from
        aws_sqs_queue
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and queue_arn = $1
      order by
        queue_arn,
        region,
        account_id
    ), kms_keys as (
      select
        aliases,
        arn,
        region,
        account_id
      from
        aws_kms_key
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
      order by
        region,
        account_id
    )
    select
      k.arn as key_arn
    from
      sqs_queue as q,
      kms_keys as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasName' = q.kms_master_key_id
      and k.region = q.region
      and k.account_id = q.account_id;
  EOQ
}

query "lambda_functions_for_sqs_queue" {
  sql = <<-EOQ
    select
      arn as function_arn
    from
      aws_lambda_function
    where
      dead_letter_config_target_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
  EOQ
}

query "queue_policy_std_for_sqs_queue" {
  sql = <<-EOQ
    select
      policy_std
    from
      aws_sqs_queue
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and queue_arn = $1;
  EOQ
}

query "s3_buckets_for_sqs_queue" {
  sql = <<-EOQ
    select
      b.arn as bucket_arn
    from
      aws_s3_bucket as b,
      jsonb_array_elements(event_notification_configuration -> 'QueueConfigurations') as q
    where
      event_notification_configuration -> 'QueueConfigurations' <> 'null'
      and q ->> 'QueueArn' = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_endpoints_for_sqs_queue" {
  sql = <<-EOQ
    select
      vpc_endpoint_id
    from
      aws_vpc_endpoint,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_vpcs_for_sqs_queue" {
  sql = <<-EOQ
    select
      vpc_id
    from
      aws_vpc_endpoint,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
  EOQ
}

# table queries

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

}
