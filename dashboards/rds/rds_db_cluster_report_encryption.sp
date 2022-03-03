dashboard "aws_rds_db_cluster_encryption_report" {

  title = "AWS RDS DB Cluster Encryption Report"

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.aws_rds_db_cluster_count.sql
      width = 2
    }

    card {
      sql = query.aws_rds_db_cluster_unencrypted_count.sql
      width = 2
    }

  }

  container {

    table {
      column "Account ID" {
        display = "none"
      }

      sql = query.aws_rds_db_cluster_encryption_table.sql
    }

  }

}

query "aws_rds_db_cluster_encryption_table" {
  sql = <<-EOQ
    select
      c.db_cluster_identifier as "DB Cluster",
      case when c.storage_encrypted then 'Enabled' else null end as "Encryption",
      c.kms_key_id as "KMS Key ID",
      a.title as "Account",
      c.account_id as "Account ID",
      c.region as "Region",
      c.arn as "ARN"
    from
      aws_rds_db_cluster as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.db_cluster_identifier;
  EOQ
}
