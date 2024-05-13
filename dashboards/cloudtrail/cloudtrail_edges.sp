edge "cloudtrail_trail_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      arn as from_id,
      log_group_arn as to_id
    from
      aws_cloudtrail_trail
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    where
      log_group_arn is not null;
  EOQ

  param "cloudtrail_trail_arns" {}
}

edge "cloudtrail_trail_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_cloudtrail_trail
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
  EOQ

  param "cloudtrail_trail_arns" {}
}

edge "cloudtrail_trail_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    with s3_bucket as (
      select
        name,
        arn
      from
        aws_s3_bucket
    )
    select
      t.arn as from_id,
      b.arn as to_id
    from
      s3_bucket as b,
      aws_cloudtrail_trail as t
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    where
      t.s3_bucket_name = b.name;
  EOQ

  param "cloudtrail_trail_arns" {}
}

edge "cloudtrail_trail_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      arn as from_id,
      sns_topic_arn as to_id
    from
      aws_cloudtrail_trail
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    where
      sns_topic_arn is not null;
  EOQ

  param "cloudtrail_trail_arns" {}
}