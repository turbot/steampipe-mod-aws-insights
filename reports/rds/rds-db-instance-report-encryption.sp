query "aws_rds_db_instance_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_rds_db_instance
    where
      not storage_encrypted
  EOQ
}


report "aws_rds_db_instance_encryption_report" {

  title = "AWS RDS DB Instance Encryption Report"

  container {

    card {
      sql = query.aws_rds_db_instance_unencrypted_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      select
        db_instance_identifier as "DB Instance",
        case when storage_encrypted then 'Enabled' else null end as "Encryption",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_rds_db_instance
    EOQ
  }

}
