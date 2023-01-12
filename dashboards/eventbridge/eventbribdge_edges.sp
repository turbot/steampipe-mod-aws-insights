edge "eventbridge_rule_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      r.arn as from_id,
      (t ->> 'Arn')::text || ':*' as to_id
    from
      aws_eventbridge_rule r,
      jsonb_array_elements(targets) t
    where
      r.arn = any($1)
      and t ->> 'Arn' like '%logs%';
  EOQ

  param "eventbridge_rule_arns" {}
}

edge "eventbridge_rule_to_eventbridge_bus" {
  title = "eventbridge rule"

  sql = <<-EOQ
    select
      b.arn as from_id,
      r.arn as to_id
    from
      aws_eventbridge_rule r
      join aws_eventbridge_bus b on b.name = r.event_bus_name
        and b.region = r.region
        and b.account_id = r.account_id
    where
      r.arn = any($1);
  EOQ

  param "eventbridge_rule_arns" {}
}

edge "eventbridge_rule_to_lambda_function" {
  title = "triggers"

  sql = <<-EOQ
    select
      r.arn as from_id,
      (t ->> 'Arn')::text as to_id
    from
      aws_eventbridge_rule r,
      jsonb_array_elements(targets) t
    where
      r.arn = any($1)
      and t ->> 'Arn' like '%lambda%';
  EOQ

  param "eventbridge_rule_arns" {}
}

edge "eventbridge_rule_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      r.arn as from_id,
      (t ->> 'Arn')::text as to_id
    from
      aws_eventbridge_rule r,
      jsonb_array_elements(targets) t
    where
      r.arn = any($1)
      and t ->> 'Arn' like '%sns%';
  EOQ

  param "eventbridge_rule_arns" {}
}

edge "eventbridge_rule_to_sqs_queue" {
  title = "queues"

  sql = <<-EOQ
    select
      arn as from_id,
      t ->> 'Arn' as to_id
    from
      aws_eventbridge_rule as r,
      jsonb_array_elements(targets) as t
    where
      t ->> 'Arn' like '%sqs%'
      and arn = any($1);
  EOQ

  param "eventbridge_rule_arns" {}
}
