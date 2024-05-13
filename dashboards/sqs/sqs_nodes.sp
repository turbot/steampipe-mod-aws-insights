
node "sqs_dead_letter_queue" {
  category = category.sqs_queue

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
      and queue_arn = any($1);
  EOQ

  param "sqs_queue_arns" {}
}

node "sqs_queue" {
  category = category.sqs_queue

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
      join unnest($1::text[]) as arn on queue_arn = arn and account_id = split_part(arn, ':', 5) and region = split_part(arn, ':', 4);
  EOQ

  param "sqs_queue_arns" {}
}

node "sqs_queue_sns_topic_subscription" {
  category = category.sns_topic_subscription

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
      endpoint = any($1);
  EOQ

  param "sqs_queue_arns" {}
}
