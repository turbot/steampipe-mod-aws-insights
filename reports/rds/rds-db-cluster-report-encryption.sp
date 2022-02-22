query "aws_rds_db_cluster_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_rds_db_cluster
    where
      not storage_encrypted
  EOQ
}

dashboard "aws_rds_db_cluster_encryption_dashboard" {

  title = "AWS RDS DB Cluster Encryption Report"

  container {

    card {
      sql = query.aws_rds_db_cluster_unencrypted_count.sql
      width = 2
    }
  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        r.db_cluster_identifier as "DB Cluster",
        case when r.storage_encrypted then 'Enabled' else null end as "Encryption",
        r.kms_key_id as "KMS Key ID",
        a.title as "Account"
        r.account_id as "Account ID",
        r.region as "Region",
        r.arn as "ARN"
      from
        aws_rds_db_cluster as r,
        aws_account as a
      where
        r.account_id = a.account_id
    EOQ
  }
}