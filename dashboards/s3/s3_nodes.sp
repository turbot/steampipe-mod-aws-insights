
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

node "s3_bucket_from_s3_bucket" {
  category = category.s3_bucket

  sql = <<-EOQ
    select
      lb.arn as id,
      lb.title as title,
      jsonb_build_object(
        'Name', lb.name,
        'ARN', lb.arn,
        'Account ID', lb.account_id,
        'Region', lb.region
      ) as properties
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = any($1)
      and lb.logging ->> 'TargetBucket' = b.name;
  EOQ

  param "s3_bucket_arns" {}
}

node "s3_bucket_to_s3_bucket" {
  category = category.s3_bucket

  sql = <<-EOQ
    select
      lb.arn as id,
      lb.title as title,
      jsonb_build_object(
        'Name', lb.name,
        'ARN', lb.arn,
        'Account ID', lb.account_id,
        'Region', lb.region
      ) as properties
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = any($1)
      and lb.name = b.logging ->> 'TargetBucket';
  EOQ

  param "s3_bucket_arns" {}
}
