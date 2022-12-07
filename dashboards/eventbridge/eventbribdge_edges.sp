
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
