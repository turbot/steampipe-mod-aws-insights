node "kinesis_stream" {
  category = category.kinesis_stream

  sql = <<-EOQ
  select
    stream_arn as id,
    title as title,
    jsonb_build_object(
      'ARN', stream_arn,
      'Status', stream_status,
      'Encryption Type', encryption_type,
      'Region', region ,
      'Account ID', account_id
    ) as properties
  from
    aws_kinesis_stream
  where
    stream_arn = any($1);
  EOQ

  param "kinesis_stream_arns" {}
}