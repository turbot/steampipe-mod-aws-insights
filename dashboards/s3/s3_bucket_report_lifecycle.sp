query "aws_s3_bucket_versioning_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not versioning_enabled;
  EOQ
}

query "aws_s3_bucket_versioning_mfa_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning MFA Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not versioning_mfa_delete;
  EOQ
}


dashboard "aws_s3_bucket_lifecycle_report" {

  title = "AWS S3 Bucket Lifecycle Report"

  tags = merge(local.s3_common_tags, {
    type     = "Report"
    category = "Lifecycle"
  })

  container {

    card {
      sql   = query.aws_s3_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_versioning_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_versioning_mfa_disabled_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        v.name as "Name",
        case when v.versioning_enabled then 'Enabled' else null end as "Versioning",
        case when v.versioning_mfa_delete then 'Enabled' else null end as "Versioning MFA Delete",
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

}
