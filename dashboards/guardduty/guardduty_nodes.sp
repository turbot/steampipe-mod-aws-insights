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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    where
      status = 'ENABLED'
      and data_sources is not null;
  EOQ

  param "guardduty_detector_arns" {}
}