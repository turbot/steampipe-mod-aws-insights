edge "sns_subscription_to_lambda_function" {
  title = "triggers"

  sql = <<-EOQ
    select
      subscription_arn as from_id,
      endpoint as to_id
    from
      aws_sns_topic_subscription
      join unnest($1::text[]) as a on subscription_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "sns_topic_subscription_arns" {}
}

edge "sns_topic_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      topic_arn as from_id,
      kms_master_key_id as to_id
    from
      aws_sns_topic
      join unnest($1::text[]) as a on topic_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "sns_topic_arns" {}
}

edge "sns_topic_to_sns_subscription" {
  title = "subscription"

  sql = <<-EOQ
    select
      topic_arn as from_id,
      subscription_arn as to_id
    from
      aws_sns_topic_subscription
    where
      topic_arn = any($1);
  EOQ

  param "sns_topic_arns" {}
}
