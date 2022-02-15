query "aws_s3_bucket_versioning_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_s3_bucket
    where
      not versioning_enabled
  EOQ
}

query "aws_s3_bucket_versioning_mfa_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning MFA Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_s3_bucket
    where
      not versioning_mfa_delete
  EOQ
}


report "aws_s3_bucket_lifecycle_report" {

  title = "AWS S3 Bucket Lifecycle Report"

  container {

    card {
      sql = query.aws_s3_bucket_versioning_disabled_count.sql
      width = 2
    }

    card {
      sql = query.aws_s3_bucket_versioning_mfa_disabled_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      select
        name as "Bucket",
        case when versioning_enabled then 'Enabled' else null end as "Versioning",
        case when versioning_mfa_delete then 'Enabled' else null end as "Versioning MFA Delete",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_s3_bucket
    EOQ
  }

}
