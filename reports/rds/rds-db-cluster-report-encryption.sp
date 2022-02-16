query "aws_rds_db_cluster_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_rds_db_cluster
    where
      not storage_encrypted
  EOQ
}

dashboard "aws_rds_db_cluster_encryption_report" {

  title = "AWS RDS DB Cluster Encryption Report"

  container {

    card {
      sql = query.aws_rds_db_cluster_unencrypted_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        db_cluster_identifier as "DB Cluster",
        case when storage_encrypted then 'Enabled' else null end as "Encryption",
        kms_key_id as "KMS Key ID",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_rds_db_cluster
    EOQ
  }
}