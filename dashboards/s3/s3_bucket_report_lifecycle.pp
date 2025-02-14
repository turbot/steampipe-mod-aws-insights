dashboard "s3_bucket_lifecycle_report" {

  title         = "AWS S3 Bucket Lifecycle Report"
  documentation = file("./dashboards/s3/docs/s3_bucket_report_lifecycle.md")

  tags = merge(local.s3_common_tags, {
    type     = "Report"
    category = "Lifecycle"
  })

  container {

    card {
      query = query.s3_bucket_count
      width = 3
    }

    card {
      query = query.s3_bucket_versioning_disabled_count
      width = 3
    }

    card {
      query = query.s3_bucket_versioning_mfa_disabled_count
      width = 3
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.s3_bucket_detail.url_path}?input.bucket_arn={{.ARN | @uri}}"
    }

    query = query.s3_bucket_lifecycle_table
  }

}

query "s3_bucket_versioning_mfa_disabled_count" {
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

query "s3_bucket_lifecycle_table" {
  sql = <<-EOQ
    select
      b.name as "Name",
      case when b.versioning_enabled then 'Enabled' else null end as "Versioning",
      case when b.versioning_mfa_delete then 'Enabled' else null end as "Versioning MFA Delete",
      b.lifecycle_rules as "Lifecycle Rules",
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
