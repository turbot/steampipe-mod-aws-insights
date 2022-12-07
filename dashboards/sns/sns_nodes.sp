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
    where
      q.topic_arn = any($1);
  EOQ

  param "sns_topic_arns" {}
}