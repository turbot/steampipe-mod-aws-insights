dashboard "aws_ebs_volume_encryption_report" {

  title = "AWS EBS Volume Encryption Report"

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.aws_ebs_volume_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ebs_volume_unencrypted_count.sql
      width = 2
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    sql = query.aws_ebs_volume_encryption_table.sql
  }

}

query "aws_ebs_volume_encryption_table" {
  sql = <<-EOQ
    select
      v.tags ->> 'Name' as "Name",
      v.volume_id as "Volume Id",
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
      v.tags ->> 'Name',
      v.volume_id;
  EOQ
}
