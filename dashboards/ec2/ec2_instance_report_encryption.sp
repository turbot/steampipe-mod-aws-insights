query "aws_ec2_default_ebs_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_regional_settings
    where
      not default_ebs_encryption_enabled;
  EOQ
}

dashboard "aws_ec2_default_ebs_encryption_count" {

  title = "AWS EC2 Default Encryption Report"

  container {

    card {
      sql   = query.aws_ec2_instance_count.sql
      width = 2
    }

    card {
      sql = query.aws_ec2_default_ebs_encryption_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      select
        account_id as "Account Id",
        region as "Region",
        case when default_ebs_encryption_enabled then 'Enabled' else 'Disabled' end as "Default EBS Encryption",
        default_ebs_encryption_key as "Default EBS Encryption Key"
      from
        aws_ec2_regional_settings;
    EOQ
  }
}
