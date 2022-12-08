node "cloudtrail_trail" {
  category = category.cloudtrail_trail

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object (
        'ARN', arn,
        'Logging', is_logging::text,
        'Latest notification time', latest_notification_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_cloudtrail_trail
    where
      arn = any($1);
  EOQ

  param "cloudtrail_trail_arns" {}
}