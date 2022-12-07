
edge "cloudformation_stack_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      s.id as from_id,
      t.topic_arn as to_id
    from
      aws_sns_topic as t,
      aws_cloudformation_stack as s,
      jsonb_array_elements(
        case jsonb_typeof(notification_arns)
          when 'array' then (notification_arns)
          else null end
      ) n
    where
      t.topic_arn = trim((n::text ), '""')
      and t.topic_arn = any($1);
  EOQ

  param "sns_topic_arns" {}
}
