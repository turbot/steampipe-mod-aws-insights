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
      v.name as "Name",
      case when v.logging -> 'TargetBucket' is not null then 'Enabled' else null end as "Logging",
      (v.logging ->> 'TargetBucket') || (v.logging ->> 'TargetPrefix') as "Target",
      v.logging -> 'TargetGrants' as "Grants",
      a.title as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.arn as "ARN"
    from
      aws_s3_bucket as v,
      aws_account as a
    where
      v.account_id = a.account_id;
  EOQ
}
