
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
      aws_sns_topic as q
    where
      q.topic_arn = any($1);
  EOQ

  param "sns_topic_arns" {}
}

node "sns_topic_subscription" {
  category = category.sns_topic_subscription

  sql = <<-EOQ
    select
      subscription_arn as id,
      left(title,8) as title,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Pending Confirmation', pending_confirmation,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sns_topic_subscription
    where
      topic_arn = any($1);
  EOQ

  param "sns_topic_arns" {}
}
