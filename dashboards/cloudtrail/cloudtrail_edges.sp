edge "cloudtrail_trail_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      arn as from_id,
      log_group_arn as to_id
    from
      aws_cloudtrail_trail
    where
      log_group_arn is not null
      and arn = any($1);
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
    where
      arn = any($1);
  EOQ

  param "cloudtrail_trail_arns" {}
}

edge "cloudtrail_trail_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      t.arn as from_id,
      b.arn as to_id
    from
      aws_s3_bucket as b,
      aws_cloudtrail_trail as t
    where
      t.s3_bucket_name = b.name
      and t.arn = any($1);
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
    where
      sns_topic_arn is not null
      and arn = any($1);
  EOQ

  param "cloudtrail_trail_arns" {}
}