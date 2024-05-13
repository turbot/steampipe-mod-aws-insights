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
    aws_dynamodb_table as t
    join unnest($1::text[]) as a on t.arn = a and t.account_id = split_part(a, ':', 5) and t.region = split_part(a, ':', 4),
    jsonb_array_elements(t.streaming_destination -> 'KinesisDataStreamDestinations') as s;
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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "dynamodb_table_arns" {}
}

edge "dynamodb_table_to_s3_bucket" {
  title = "exports to"

  sql = <<-EOQ
    with s3_bucket as (
      select
        arn,
        name
      from
        aws_s3_bucket
    )
    select
      table_arn as from_id,
      b.arn as to_id
    from
      aws_dynamodb_table_export as t,
      s3_bucket as b
    where
      b.name = t.s3_bucket
      and t.table_arn = any($1);
  EOQ

  param "dynamodb_table_arns" {}
}
