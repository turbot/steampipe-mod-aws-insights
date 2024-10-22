edge "cloudwatch_log_group_to_cloudwatch_log_metric_filter_edge" {
  title = "metric filter"

  sql = <<-EOQ
    select
      g.arn as from_id,
      f.name as to_id
    from
      aws_cloudwatch_log_group as g,
      aws_cloudwatch_log_metric_filter as f
    where
      g.name = f.log_group_name
      and f.region = g.region
      and g.arn = any($1);
  EOQ

  param "cloudwatch_log_group_arns" {}
}

edge "cloudwatch_log_group_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_cloudwatch_log_group
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "cloudwatch_log_group_arns" {}
}

