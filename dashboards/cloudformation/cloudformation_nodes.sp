
node "cloudformation_stack" {
  category = category.cloudformation_stack

  sql = <<-EOQ
    select
      s.id as id,
      title as title,
      jsonb_build_object(
        'ARN', s.id,
        'Last Updated Time', s.last_updated_time,
        'Status', s.status,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_cloudformation_stack as s,
      jsonb_array_elements(
        case jsonb_typeof(notification_arns)
          when 'array' then (notification_arns)
          else null end
      ) n
    where
      trim((n::text ), '""') = any($1);
  EOQ

  param "sns_topic_arns" {}
}
