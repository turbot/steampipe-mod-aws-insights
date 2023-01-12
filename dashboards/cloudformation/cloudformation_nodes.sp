node "cloudformation_stack" {
  category = category.cloudformation_stack

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ARN', id,
        'Last Updated Time', last_updated_time,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_cloudformation_stack
    where
      id = any($1);
  EOQ

  param "cloudformation_stack_ids" {}
}
