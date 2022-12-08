
edge "sqs_queue_to_kms_key" {
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
      and q.queue_arn = any($1);
  EOQ

  param "sqs_queue_arns" {}
}

edge "sqs_queue_to_kms_key_alias" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      q.queue_arn as from_id,
      a.arn as to_id
    from
      aws_kms_key as k
      join aws_kms_alias as a
      on a.target_key_id = k.id
      join aws_sqs_queue as q
      on a.alias_name = q.kms_master_key_id
      and k.region = q.region
      and k.account_id = q.account_id
    where
      q.queue_arn = any($1);
  EOQ

  param "sqs_queue_arns" {}
}

edge "sqs_queue_to_sns_topic_subscription" {
  title = "subscription"

  sql = <<-EOQ
    select
      endpoint as from_id,
      subscription_arn as to_id
    from
      aws_sns_topic_subscription
    where
      endpoint = any($1);
  EOQ

  param "sqs_queue_arns" {}
}

edge "sqs_queue_to_sqs_dead_letter_queue" {
  title = "dead letter queue"

  sql = <<-EOQ
    select
      queue_arn as from_id,
      redrive_policy ->> 'deadLetterTargetArn' as to_id
    from
      aws_sqs_queue
    where
      redrive_policy ->> 'deadLetterTargetArn' is not null
      and queue_arn = any($1);
  EOQ

  param "sqs_queue_arns" {}
}

edge "sqs_queue_to_vpc_endpoint" {
  title = "endpoint"

  sql = <<-EOQ
    select
      r as from_id,
      vpc_endpoint_id as to_id
    from
      aws_vpc_endpoint,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Resource') as r
    where
      r = any($1);
  EOQ

  param "sqs_queue_arns" {}
}
