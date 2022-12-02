node "dynamodb_table_to_kinesis_stream_node" {
  category = category.kinesis_stream

  sql = <<-EOQ
  select
    s.stream_arn as id,
    s.title as title,
    jsonb_build_object(
      'ARN', s.stream_arn,
      'Status', stream_status,
      'Encryption Type', encryption_type,
      'Region', s.region ,
      'Account ID', s.account_id
    ) as properties
  from
    aws_kinesis_stream as s,
    aws_dynamodb_table as t,
    jsonb_array_elements(t.streaming_destination -> 'KinesisDataStreamDestinations') as d
  where
    d ->> 'StreamArn' = s.stream_arn
    and t.arn = any($1);
  EOQ

  param "dynamodb_table_arns" {}
}
