dashboard "aws_rds_db_instace_snapshot_encryption_report" {

  title = "AWS RDS DB Instance Snapshot Encryption Report"

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.aws_rds_db_instance_snapshot_count.sql
      width = 2
    }

    card {
      sql = query.aws_rds_db_instance_snapshot_unencrypted_count.sql
    }

  }

  container {

    table {

      column "Account ID" {
        display = "none"
      }

      sql = query.aws_rds_db_instance_snapshot_encryption_table.sql
    }
    
  }

}

query "aws_rds_db_instance_snapshot_encryption_table" {
  sql = <<-EOQ
    select
      s.title as "Snapshot",
      case when encrypted then 'Enabled' else null end as "Encryption",
      a.title as "Account",
      s.account_id as "Account ID",
      s.region as "Region",
      s.arn as "ARN"
    from
      aws_rds_db_snapshot as s,
      aws_account as a
    where
      s.account_id = a.account_id
    order by
      s.title;
  EOQ
}
