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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "cloudtrail_trail_arns" {}
}