node "cloudwatch_log_group" {
  category = category.cloudwatch_log_group

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Creation Time', creation_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_cloudwatch_log_group
    where
      arn = any($1);
  EOQ

  param "cloudwatch_log_group_arns" {}
}

node "cloudwatch_log_metric_filter" {
  category = category.cloudwatch_log_metric_filter

  sql = <<-EOQ
    select
      f.name as id,
      f.title as title,
      jsonb_build_object(
        'Creation Time', f.creation_time,
        'Metric Transformation Name', f.metric_transformation_name,
        'Metric Transformation Namespace', f.metric_transformation_namespace,
        'Metric Transformation Value', f.metric_transformation_value,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      left join aws_cloudwatch_log_metric_filter as f on g.name = f.log_group_name
    where
      f.region = g.region
      and g.arn = any($1);
  EOQ

  param "cloudwatch_log_group_arns" {}
}
