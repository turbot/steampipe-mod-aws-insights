node "dynamodb_backup" {
  category = category.dynamodb_backup

  sql = <<-EOQ
  select
    b.arn as id,
    b.title as title,
    jsonb_build_object(
      'ARN', b.arn,
      'Status', b.backup_status,
      'Creation Date', b.backup_creation_datetime,
      'Region', b.region ,
      'Account ID', b.account_id
    ) as properties
  from
    aws_dynamodb_backup as b
    join unnest($1::text[]) as a on b.arn = a and b.account_id = split_part(a, ':', 5) and b.region = split_part(a, ':', 4);
  EOQ

  param "dbynamodb_backup_arns" {}
}

node "dynamodb_table" {
  category = category.dynamodb_table

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Creation Date', creation_date_time,
        'Table Status', table_status,
        'Account ID', account_id
      ) as properties
    from
      aws_dynamodb_table
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "dynamodb_table_arns" {}
}
