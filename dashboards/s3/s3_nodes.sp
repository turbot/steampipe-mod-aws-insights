
node "s3_bucket" {
  category = category.s3_bucket

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_bucket
    where
      arn = any($1);
  EOQ

  param "s3_bucket_arns" {}
}

