edge "lambda_function_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      f.arn as from_id,
      g.arn as to_id
    from
      aws_cloudwatch_log_group as g
      left join aws_lambda_function as f on f.name = split_part(g.name, '/', 4)
    where
      g.name like '/aws/lambda/%'
      and g.region = f.region
      and f.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}