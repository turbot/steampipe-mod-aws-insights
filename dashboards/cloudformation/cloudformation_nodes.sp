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
      join unnest($1::text[]) as a on id = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "cloudformation_stack_ids" {}
}
