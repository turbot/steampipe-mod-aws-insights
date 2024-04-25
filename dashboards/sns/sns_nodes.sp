
node "sns_topic" {
  category = category.sns_topic

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
      aws_sns_topic
      join unnest($1::text[]) as arn on topic_arn = arn and account_id = split_part(arn, ':', 5) and region = split_part(arn, ':', 4);
  EOQ

  param "sns_topic_arns" {}
}

node "sns_topic_subscription" {
  category = category.sns_topic_subscription

  sql = <<-EOQ
    select
      subscription_arn as id,
      split_part(title, '-', 1) as title,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Endpoint', endpoint,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_sns_topic_subscription
    where
      subscription_arn = any($1);
  EOQ

  param "sns_topic_subscription_arns" {}
}
