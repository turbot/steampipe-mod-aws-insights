dashboard "aws_rds_db_cluster_snapshot_encryption_report" {

  title = "AWS RDS DB Cluster Snapshot Encryption Report"

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.aws_rds_db_cluster_snapshot_count.sql
      width = 2
    }

    card {
      sql = query.aws_rds_db_cluster_snapshot_unencrypted_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = query.aws_rds_db_cluster_snapshot_encryption_table.sql
  }

}

query "aws_rds_db_cluster_snapshot_encryption_table" {
  sql = <<-EOQ
    select
      title as "Snapshot",
      case when storage_encrypted then 'Enabled' else null end as "Encryption",
      account_id as "Account",
      region as "Region",
      arn as "ARN"
    from
      aws_rds_db_cluster_snapshot;
  EOQ
}
