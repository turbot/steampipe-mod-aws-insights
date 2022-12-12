node "guardduty_detector" {
  category = category.guardduty_detector

  sql = <<-EOQ
    select
      arn as id,
      left(title,8) as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Status', status
      ) as properties
    from
      aws_guardduty_detector
    where
      status = 'ENABLED'
      and data_sources is not null
      and arn = any($1);
  EOQ

  param "guardduty_detector_arns" {}
}