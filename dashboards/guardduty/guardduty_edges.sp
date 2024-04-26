edge "guardduty_detector_to_cloudtrail_trail" {
  title = "cloudtrail trail"

  sql = <<-EOQ
    select
      d.arn as from_id,
      t.arn as to_id
    from
      aws_guardduty_detector as d
      join unnest($1::text[]) as a on d.arn = a and d.account_id = split_part(a, ':', 5) and d.region = split_part(a, ':', 4),
      aws_cloudtrail_trail as t
    where
      d.status = 'ENABLED'
      and d.data_sources is not null
      and d.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED';
  EOQ

  param "guardduty_detector_arns" {}
}

edge "guardduty_detector_to_iam_role" {
  title = "runs as"

  sql = <<-EOQ
    select
      detector_id as from_id,
      service_role as to_id
    from
      aws_guardduty_detector
    where
      service_role = any($1);
  EOQ

  param "iam_role_arns" {}
}