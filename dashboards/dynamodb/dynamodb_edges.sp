
edge "dynamodb_table_to_dynamodb_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      table_arn as from_id,
      arn as to_id
    from
      aws_dynamodb_backup
    where
      table_arn = any($1);
  EOQ

  param "dynamodb_table_arns" {}
}

edge "dynamodb_table_to_kinesis_stream" {
  title = "streams to"

  sql = <<-EOQ
  select
    arn as from_id,
    s ->> 'StreamArn' as to_id
  from
    aws_dynamodb_table as t,
    jsonb_array_elements(t.streaming_destination -> 'KinesisDataStreamDestinations') as s
  where
    arn = any($1);
  EOQ

  param "dynamodb_table_arns" {}
}

edge "dynamodb_table_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      sse_description ->> 'KMSMasterKeyArn' as to_id,
      arn as from_id
    from
      aws_dynamodb_table
    where
      arn = any($1);
  EOQ

  param "dynamodb_table_arns" {}
}

edge "dynamodb_table_to_s3_bucket" {
  title = "exports to"

  sql = <<-EOQ
    select
      table_arn as from_id,
      b.arn as to_id
    from
      aws_dynamodb_table_export as t,
      aws_s3_bucket as b
    where
      b.name = t.s3_bucket
      and t.table_arn = any($1);
  EOQ

  param "dynamodb_table_arns" {}
}
