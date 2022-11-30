dashboard "rds_db_cluster_snapshot_encryption_report" {

  title         = "AWS RDS DB Cluster Snapshot Encryption Report"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_snapshot_report_encryption.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.rds_db_cluster_snapshot_count
      width = 2
    }

    card {
      query = query.rds_db_cluster_snapshot_unencrypted_count
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

    column "DB Cluster Snapshot Identifier" {
      href = "${dashboard.rds_db_cluster_snapshot_detail.url_path}?input.snapshot_arn={{.ARN | @uri}}"
    }

    query = query.rds_db_cluster_snapshot_encryption_table
  }

}

query "rds_db_cluster_snapshot_encryption_table" {
  sql = <<-EOQ
    select
      s.db_cluster_snapshot_identifier as "DB Cluster Snapshot Identifier",
      case when storage_encrypted then 'Enabled' else null end as "Encryption",
      s.kms_key_id as "KMS Key ID",
      a.title as "Account",
      s.account_id as "Account ID",
      s.region as "Region",
      s.arn as "ARN"
    from
      aws_rds_db_cluster_snapshot as s,
      aws_account as a
    where
      s.account_id = a.account_id
    order by
      s.db_cluster_snapshot_identifier;
  EOQ
}
