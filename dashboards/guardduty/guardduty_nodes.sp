node "guardduty_detector" {
  category = category.guardduty_detector

  sql = <<-EOQ
    select
      detector_id as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Created At', created_at,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_guardduty_detector
    where
      service_role = any($1);
  EOQ

  param "iam_role_arns" {}
}
