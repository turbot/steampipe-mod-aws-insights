
node "eventbridge_bus" {
  category = category.eventbridge_bus

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Event Bus Name', name,
        'Region', region
      ) as properties
    from
      aws_eventbridge_bus
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "eventbridge_bus_arns" {}
}

node "eventbridge_rule" {
  category = category.eventbridge_rule

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Event Bus Name', event_bus_name,
        'Managed by', managed_by,
        'Region', region,
        'State', state
      ) as properties
    from
      aws_eventbridge_rule
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "eventbridge_rule_arns" {}
}
