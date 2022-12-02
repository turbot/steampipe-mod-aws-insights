node "iam_role" {
  category = category.iam_role

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_role
    where
      arn = any($1 ::text[]);
  EOQ

  param "iam_role_arns" {}
}
