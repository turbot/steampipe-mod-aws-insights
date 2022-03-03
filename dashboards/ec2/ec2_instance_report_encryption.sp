dashboard "aws_ec2_default_ebs_encryption_report" {

  title = "AWS EC2 Default Encryption Report"

  tags = merge(local.ec2_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

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
    column "Account ID" {
      display = "none"
    }
    
    sql = query.aws_ec2_default_ebs_encryption_table.sql
  }
}

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

query "aws_ec2_default_ebs_encryption_table" {
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

