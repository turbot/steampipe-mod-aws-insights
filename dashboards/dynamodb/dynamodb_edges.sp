edge "dynamodb_table_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      kms_key_arn as to_id,
      dynamodb_table_arn as from_id
    from
      unnest($1::text[]) as kms_key_arn,
      unnest($2::text[]) as dynamodb_table_arn
  EOQ

  param "kms_key_arns" {}
  param "dynamodb_table_arns" {}
}

edge "dynamodb_table_to_s3_bucket" {
  title = "exports to"

  sql = <<-EOQ
    select
      dynamodb_table_arn as from_id,
      s3_bucket_arn as to_id
    from
      unnest($1::text[]) as dynamodb_table_arn,
      unnest($2::text[]) as s3_bucket_arn
  EOQ

  param "dynamodb_table_arns" {}
  param "s3_bucket_arns" {}
}

edge "dynamodb_table_to_dynamodb_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      dynamodb_table_arn as from_id,
      dbynamodb_backup_arn as to_id
    from
      unnest($1::text[]) as dynamodb_table_arn,
      unnest($2::text[]) as dbynamodb_backup_arn
  EOQ

  param "dynamodb_table_arns" {}
  param "dbynamodb_backup_arns" {}
}

edge "dynamodb_table_to_kinesis_stream" {
  title = "streams to"

  sql = <<-EOQ
  select
    dynamodb_table_arn as from_id,
    kinesis_stream_arn as to_id
  from
    unnest($1::text[]) as dynamodb_table_arn,
    unnest($2::text[]) as kinesis_stream_arn
  EOQ

  param "dynamodb_table_arns" {}
  param "kinesis_stream_arns" {}
}
