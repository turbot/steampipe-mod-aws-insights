dashboard "aws_ebs_volume_encryption_dashboard" {
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
      sql = <<-EOQ
        select
          count(*) as value,
          'Unencrypted' as label,
          case count(*) when 0 then 'ok' else 'alert' end as type
        from
          aws_ebs_volume
        where
          not encrypted;
      EOQ
      width = 2
    }
    
  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        v.tags ->> 'Name' as "Name",
        v.volume_id as "Volume",
        case when v.encrypted then 'Enabled' else null end as "Encryption",
        a.title as "Account",
        v.account_id as "Account ID",
        v.region as "Region",
        v.arn as "ARN"
      from
        aws_ebs_volume as v,
        aws_account as a
      where
        v.account_id = a.account_id;
    EOQ

  }

}
