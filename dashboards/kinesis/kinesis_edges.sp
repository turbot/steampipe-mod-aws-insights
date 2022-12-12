edge "kinesis_stream_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      s.stream_arn as from_id,
      g.arn as to_id
    from
      aws_cloudwatch_log_group as g
      left join aws_cloudwatch_log_subscription_filter as f on g.name = f.log_group_name
      right join aws_kinesis_stream as s on s.stream_arn = f.destination_arn
    where
      f.region = g.region
      and stream_arn = any($1);
  EOQ

  param "kinesis_stream_arns" {}
}