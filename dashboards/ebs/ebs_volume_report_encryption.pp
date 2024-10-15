dashboard "ebs_volume_encryption_report" {

  title         = "AWS EBS Volume Encryption Report"
  documentation = file("./dashboards/ebs/docs/ebs_volume_report_encryption.md")

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.ebs_volume_count
      width = 3
    }

    card {
      query = query.ebs_volume_unencrypted_count
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

    column "Volume ID" {
      href = "${dashboard.ebs_volume_detail.url_path}?input.volume_arn={{.ARN | @uri}}"
    }

    query = query.ebs_volume_encryption_table
  }

}

query "ebs_volume_encryption_table" {
  sql = <<-EOQ
    select
      v.volume_id as "Volume ID",
      v.tags ->> 'Name' as "Name",
      case when v.encrypted then 'Enabled' else null end as "Encryption",
      v.kms_key_id as "KMS Key ID",
      a.title as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.arn as "ARN"
    from
      aws_ebs_volume as v,
      aws_account as a
    where
      v.account_id = a.account_id
    order by
      v.volume_id;
  EOQ
}
