query "aws_rds_db_instance_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_instance
    where
      not storage_encrypted
  EOQ
}

dashboard "aws_rds_db_instance_encryption_dashboard" {

  title = "AWS RDS DB Instance Encryption Report"

  container {

    card {
      sql = query.aws_rds_db_instance_unencrypted_count.sql
      width = 2
    }
  }

  table {

    column "Account ID" {
        display = "none"
    }

    sql = <<-EOQ
      select
        i.db_instance_identifier as "DB Instance Identifier",
        case when i.storage_encrypted then 'Enabled' else null end as "Encryption",
        a.title as "Account",
        i.account_id as "Account ID",
        i.region as "Region",
        i.arn as "ARN"
      from
        aws_rds_db_instance as i,
        aws_account as a
      where
        i.account_id = a.account_id
    EOQ
  }
}
