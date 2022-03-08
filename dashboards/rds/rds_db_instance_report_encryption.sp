dashboard "aws_rds_db_instance_encryption_report" {

  title = "AWS RDS DB Instance Encryption Report"

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.aws_rds_db_instance_count.sql
      width = 2
    }

    card {
      sql = query.aws_rds_db_instance_unencrypted_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "DB Instance Identifier" {
      href = "/aws_insights.dashboard.aws_rds_db_instance_detail?input.db_instance_arnn={{.ARN|@uri}}"
    }

    sql = query.aws_rds_db_instance_encryption_table.sql
  }

}

query "aws_rds_db_instance_encryption_table" {
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
    order by
      i.db_instance_identifier;
  EOQ
}
