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

edge "cloudtrail_trail_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      arn as from_id,
      sns_topic_arn as to_id
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
      aws_cloudtrail_trail as t,
      aws_s3_bucket as b
    where
      t.arn = any($1)
      and t.s3_bucket_name = b.name;
  EOQ

  param "cloudtrail_trail_arns" {}
}
