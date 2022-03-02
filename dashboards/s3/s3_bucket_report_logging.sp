dashboard "aws_s3_bucket_logging_report" {

  title = "AWS S3 Bucket Logging Report"

  tags = merge(local.s3_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      sql   = query.aws_s3_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_logging_disabled_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = query.aws_s3_bucket_logging_table.sql

  }

}

query "aws_s3_bucket_logging_table" {
  sql = <<-EOQ
    select
      b.name as "Name",
      case when b.logging -> 'TargetBucket' is not null then 'Enabled' else null end as "Logging",
      (b.logging ->> 'TargetBucket') || (b.logging ->> 'TargetPrefix') as "Target",
      b.logging -> 'TargetGrants' as "Grants",
      a.title as "Account",
      b.account_id as "Account ID",
      b.region as "Region",
      b.arn as "ARN"
    from
      aws_s3_bucket as b,
      aws_account as a
    where
      b.account_id = a.account_id
    order by
      b.name;
  EOQ
}
