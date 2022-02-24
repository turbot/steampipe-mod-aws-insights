dashboard "aws_rds_db_cluster_snapshot_encryption_dashboard" {
  title = "AWS RDS DB Cluster Snapshot Encryption Report"

  container {

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          'Unencrypted' as label,
          case count(*) when 0 then 'ok' else 'alert' end as type
        from
          aws_rds_db_cluster_snapshot
        where
          not storage_encrypted;
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
        title as "Snapshot",
        case when storage_encrypted then 'Enabled' else null end as "Encryption",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_rds_db_cluster_snapshot;
    EOQ
  }

}