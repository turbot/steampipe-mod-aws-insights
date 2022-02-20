dashboard "aws_ebs_volume_encryption_dashboard" {
  title = "AWS EBS Volume Encryption Report"

  container {

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
    sql = <<-EOQ
      select
        title as "Volume",
        case when encrypted then 'Enabled' else null end as "Encryption",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_ebs_volume;
    EOQ
  }

}