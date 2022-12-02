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
    where
      arn = any($1);
  EOQ

  param "dynamodb_table_arns" {}
}

node "dynamodb_table_to_dynamodb_backup_node" {
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
  where
    b.table_arn = any($1);
  EOQ

  param "dbynamodb_backup_arns" {}
}
