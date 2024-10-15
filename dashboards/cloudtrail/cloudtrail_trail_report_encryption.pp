dashboard "cloudtrail_trail_encryption_report" {

  title         = "AWS CloudTrail Trail Encryption Report"
  documentation = file("./dashboards/cloudtrail/docs/cloudtrail_trail_report_encryption.md")

  tags = merge(local.cloudtrail_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.cloudtrail_trail_count
      width = 3
    }

    card {
      query = query.cloudtrail_trail_unencrypted_count
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
      href = "${dashboard.cloudtrail_trail_detail.url_path}?input.trail_arn={{.ARN | @uri}}"
    }

    query = query.cloudtrail_trail_encryption_table

  }

}

query "cloudtrail_trail_encryption_table" {
  sql = <<-EOQ
    select
      t.name as "Name",
      case when t.kms_key_id is not null then 'Enabled' else null end as "Encryption",
      a.title as "Account",
      t.account_id as "Account ID",
      t.region as "Region",
      t.arn as "ARN"
    from
      aws_cloudtrail_trail as t,
      aws_account as a
    where
      t.home_region = t.region
      and t.account_id = a.account_id
    order by
      t.name;
  EOQ
}
